//---------------------------------------------------------------------------------
//
//  Swift port of the libnds PXI example (ARM9 side).  -- fincs (original)
//
//  Demonstrates ARM9<->ARM7 communication over a user PXI channel: the ARM9
//  sends command words and the custom ARM7 server (arm7/arm7.c) replies. Command
//  0 returns the firmware chip's JEDEC ID; command 1 returns raw touch Z1/Z2,
//  from which the touch pressure is computed (DS Phat/Lite only).
//
//  This is the project's only dual-CPU example: the Makefile sets ARM7_SRC so a
//  custom ARM7 binary is built and packaged in place of calico's default one.
//
//---------------------------------------------------------------------------------

import CNDS

// Function-like fixed-point macros (don't import).
@inline(__always) func inttof32(_ n: Int32) -> Int32 { n << 12 }
@inline(__always) func f32tofloat(_ n: Int32) -> Float { Float(n) / Float(1 << 12) }

// KEY_TOUCH is BIT(14), which the importer drops.
let KEY_TOUCH: UInt32 = 1 << 14

//---------------------------------------------------------------------------------
// pressure = 1/resistance = z1 / (x * (z2 - z1)), via the hardware divider,
// arranged to avoid division by zero / the z1 == z2 indetermination.
//---------------------------------------------------------------------------------
func calcTouchPressure(_ px: UInt32, _ z1: UInt32, _ z2: UInt32) -> Int32 {
	let num = divf32(Int32(bitPattern: z1), Int32(bitPattern: px))
	let den = Int32(bitPattern: z2) - Int32(bitPattern: z1)
	if num == den { return inttof32(1) }
	return divf32(num, den)
}

var touch = touchPosition()

_ = consoleDemoInit()

// Wait for the ARM7 PXI server to come up before sending commands.
pxiWaitRemote(PxiChannel_User0)

nds_puts("\n\n\tHello DS dev'rs\n")
nds_puts("\thttps://devkitpro.org\n\n")

let jedec = pxiSendAndReceive(PxiChannel_User0, 0)   // command 0: firmware JEDEC ID
nds_printf_1i("Firmware JEDEC ID: 0x%06lX\n", Int32(bitPattern: jedec))

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	if keysHeld() & KEY_TOUCH != 0 {
		_ = touchRead(&touch)

		let reply = pxiSendAndReceive(PxiChannel_User0, 1)   // command 1: raw Z1/Z2
		let pressure = calcTouchPressure(UInt32(touch.rawx), reply & 0xFFF, reply >> 12)

		nds_printf_2i("\u{1b}[10;0HTouch x = %04i, %04i\n", Int32(touch.rawx), Int32(touch.px))
		nds_printf_2i("Touch y = %04i, %04i\n", Int32(touch.rawy), Int32(touch.py))
		nds_printf_1f("Touch pressure: %.6f\n", Double(f32tofloat(pressure)))
	}
}
