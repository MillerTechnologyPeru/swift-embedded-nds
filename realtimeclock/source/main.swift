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

import NDS

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
	GL.begin(.quads)
	GL.vertex(x - width / 2, y,          0)
	GL.vertex(x + width / 2, y,          0)
	GL.vertex(x + width / 2, y + height, 0)
	GL.vertex(x - width / 2, y + height, 0)
	GL.end()
}

func init3D() {
	System.lcdMainOnTop()
	Video.setMode(.mode0_3D)
	GL.initialize()
	GL.viewport(0, 0, 255, 191)
	GL.clearColor(r: 0, g: 0, b: 0, a: 31)
	GL.clearDepth(0x7FFF)
	GL.polyFmt(POLY_ALPHA(31) | UInt32(POLY_CULL_NONE.rawValue))

	GL.matrixMode(.modelview)
	GL.loadIdentity()
	GL.matrixMode(.projection)
	GL.loadIdentity()
	GL.perspective(fovy: 70, aspect: 256.0 / 192.0, near: 0.1, far: 100)
	GL.lookAt(eye:    (0.0, 0.0, 3.0),
	          center: (0.0, 0.0, 0.0),
	          up:     (0.0, 1.0, 0.0))
}

func update3D(_ hours: Int, _ seconds: Int, _ minutes: Int) {
	// second hand
	GL.pushMatrix()
	GL.color(0, 0, 1)
	GL.rotateZ(Float(-seconds * 360 / 60))
	GL.translate(0, 1.9, 0)
	drawQuad(0, 0, 0.2, 0.2)
	GL.popMatrix()

	// minute hand
	GL.pushMatrix()
	GL.color(0, 1, 0)
	GL.rotateZ(Float(-minutes * 360 / 60))
	drawQuad(0, 0, 0.2, 2)
	GL.popMatrix()

	// hour hand
	GL.pushMatrix()
	GL.color(1, 0, 0)
	GL.rotateZ(Float(-hours * 360 / 12))
	drawQuad(0, 0, 0.3, 1.8)
	GL.popMatrix()

	GL.flush()
}

//---------------------------------------------------------------------------------
// Main
//---------------------------------------------------------------------------------
Console.demoInit()
init3D()

while System.mainLoop {
	let t = RTC.now()
	let month0 = Int(t.month) - 1   // 0-based for month-name / day-of-week tables

	Console.print("\u{1b}[2J")   // clear console
	Console.printf("%02i:%02i:%02i", t.hour, t.minute, t.second)

	let dow = getDayOfWeek(Int(t.day), month0, Int(t.year))
	Console.print("\n")
	Console.print(weekDays[dow])
	Console.print(" ")
	Console.print(months[month0])
	Console.printf(" %i %i", t.day, t.year)

	update3D(Int(t.hour), Int(t.second), Int(t.minute))

	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
