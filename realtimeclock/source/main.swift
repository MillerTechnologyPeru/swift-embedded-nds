//---------------------------------------------------------------------------------
//
//  Swift port of the libnds RealTimeClock example.
//
//  Reads the hardware real-time clock and shows a digital clock + date on the
//  sub-screen console, plus a "cheesy watch face" of three 3D quad hands
//  (hour/minute/second) on the top screen.
//
//  (The RTC is read through the calico API via a small shim, since calico does
//  not wire newlib's time() to the clock on this target.)
//
//---------------------------------------------------------------------------------

import CNDS

let months = ["January", "February", "March", "April", "May", "June",
              "July", "August", "September", "October", "November", "December"]

let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

// days-since-Jan-1 at the start of each month, mod 7
let daysAtStartOfMonth: [Int] = [
	0 % 7, 31 % 7, 59 % 7, 90 % 7, 120 % 7, 151 % 7,
	181 % 7, 212 % 7, 243 % 7, 273 % 7, 304 % 7, 334 % 7,
]

@inline(__always) func isLeapYear(_ year: Int) -> Bool { year % 4 == 0 }

// Sakamoto-style day-of-week (Wikipedia "Calculating the day of the week").
func getDayOfWeek(_ dayIn: Int, _ month: Int, _ yearIn: Int) -> Int {
	var day = dayIn
	day += 2 * (3 - ((yearIn / 100) % 4))
	let year = yearIn % 100
	day += year + (year / 4)
	day += daysAtStartOfMonth[month] - ((isLeapYear(year) && month <= 1) ? 1 : 0)
	return ((day % 7) + 7) % 7
}

//---------------------------------------------------------------------------------
// 3D watch face
//---------------------------------------------------------------------------------
func drawQuad(_ x: Float, _ y: Float, _ width: Float, _ height: Float) {
	glBegin(GL_QUADS)
	glVertex3f(x - width / 2, y,          0)
	glVertex3f(x + width / 2, y,          0)
	glVertex3f(x + width / 2, y + height, 0)
	glVertex3f(x - width / 2, y + height, 0)
	glEnd()
}

func init3D() {
	lcdMainOnTop()
	videoSetMode(MODE_0_3D.rawValue)
	glInit()
	glViewport(0, 0, 255, 191)
	glClearColor(0, 0, 0, 31)
	glClearDepth(0x7FFF)
	glPolyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()
	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	gluPerspective(70, 256.0 / 192.0, 0.1, 100)
	gluLookAt(0.0, 0.0, 3.0,   // camera
	          0.0, 0.0, 0.0,   // look at
	          0.0, 1.0, 0.0)   // up
}

func update3D(_ hours: Int, _ seconds: Int, _ minutes: Int) {
	// second hand
	glPushMatrix()
	glColor3f(0, 0, 1)
	glRotateZ(Float(-seconds * 360 / 60))
	glTranslatef(0, 1.9, 0)
	drawQuad(0, 0, 0.2, 0.2)
	glPopMatrix(1)

	// minute hand
	glPushMatrix()
	glColor3f(0, 1, 0)
	glRotateZ(Float(-minutes * 360 / 60))
	drawQuad(0, 0, 0.2, 2)
	glPopMatrix(1)

	// hour hand
	glPushMatrix()
	glColor3f(1, 0, 0)
	glRotateZ(Float(-hours * 360 / 12))
	drawQuad(0, 0, 0.3, 1.8)
	glPopMatrix(1)

	glFlush(0)
}

//---------------------------------------------------------------------------------
// Main
//---------------------------------------------------------------------------------
_ = consoleDemoInit()
init3D()

var year: Int32 = 0, month: Int32 = 0, day: Int32 = 0
var hour: Int32 = 0, minute: Int32 = 0, second: Int32 = 0

while pmMainLoop() {
	nds_rtc_read(&year, &month, &day, &hour, &minute, &second)
	let month0 = Int(month) - 1   // 0-based for month-name / day-of-week tables

	nds_puts("\u{1b}[2J")   // clear console
	nds_printf_3i("%02i:%02i:%02i", hour, minute, second)

	let dow = getDayOfWeek(Int(day), month0, Int(year))
	nds_puts("\n")
	nds_puts(weekDays[dow])
	nds_puts(" ")
	nds_puts(months[month0])
	nds_printf_2i(" %i %i", day, year)

	update3D(Int(hour), Int(second), Int(minute))

	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
