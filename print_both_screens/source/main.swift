//---------------------------------------------------------------------------------
//
//  Swift port of the libnds print_both_screens example.
//
//  Sets up a text console on each screen and prints to both.
//
//---------------------------------------------------------------------------------

import NDS

var touch = touchPosition()

var topScreen = PrintConsole()
var bottomScreen = PrintConsole()

Video.setMode(.mode0_2D)
Video.setModeSub(.mode0_2D)

Video.setBankA(VRAM_A_MAIN_BG)
Video.setBankC(VRAM_C_SUB_BG)

Console.initialize(&topScreen, layer: 3, kind: .text4bpp, size: BgSize_T_256x256, mapBase: 31, tileBase: 0, mainDisplay: true)
Console.initialize(&bottomScreen, layer: 3, kind: .text4bpp, size: BgSize_T_256x256, mapBase: 31, tileBase: 0, mainDisplay: false)

Console.select(&topScreen)
Console.print("\n\n\tHello DS dev'rs\n")
Console.print("\twww.drunkencoders.com\n")
Console.print("\twww.devkitpro.org")

Console.select(&bottomScreen)

while System.mainLoop {
	_ = Touch.read(into: &touch)

	Console.printf("\u{1b}[10;0HTouch x = %04i, %04i\n", Int32(touch.rawx), Int32(touch.px))
	Console.printf("Touch y = %04i, %04i\n", Int32(touch.rawy), Int32(touch.py))

	System.waitForVBlank()
	Keys.scan()

	if Keys.down.contains(.start) { break }
}
