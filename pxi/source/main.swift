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

import NDS

//---------------------------------------------------------------------------------
// pressure = 1/resistance = z1 / (x * (z2 - z1)), via the hardware divider,
// arranged to avoid division by zero / the z1 == z2 indetermination.
//---------------------------------------------------------------------------------
func calcTouchPressure(_ px: UInt32, _ z1: UInt32, _ z2: UInt32) -> Int32 {
	let num = Math.divf32(Int32(bitPattern: z1), Int32(bitPattern: px))
	let den = Int32(bitPattern: z2) - Int32(bitPattern: z1)
	if num == den { return inttof32(1) }
	return Math.divf32(num, den)
}

var touch = touchPosition()

Console.demoInit()

// Wait for the ARM7 PXI server to come up before sending commands.
pxiWaitRemote(PxiChannel_User0)

Console.print("\n\n\tHello DS dev'rs\n")
Console.print("\thttps://devkitpro.org\n\n")

let jedec = pxiSendAndReceive(PxiChannel_User0, 0)   // command 0: firmware JEDEC ID
Console.printf("Firmware JEDEC ID: 0x%06lX\n", Int32(bitPattern: jedec))

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }

	if Keys.held.contains(.touch) {
		_ = Touch.read(into: &touch)

		let reply = pxiSendAndReceive(PxiChannel_User0, 1)   // command 1: raw Z1/Z2
		let pressure = calcTouchPressure(UInt32(touch.rawx), reply & 0xFFF, reply >> 12)

		Console.printf("\u{1b}[10;0HTouch x = %04i, %04i\n", Int32(touch.rawx), Int32(touch.px))
		Console.printf("Touch y = %04i, %04i\n", Int32(touch.rawy), Int32(touch.py))
		Console.printf("Touch pressure: %.6f\n", Double(f32tofloat(pressure)))
	}
}
