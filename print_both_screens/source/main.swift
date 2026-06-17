//---------------------------------------------------------------------------------
//
//  Swift port of the libnds print_both_screens example.
//
//  Sets up a text console on each screen and prints to both.
//
//---------------------------------------------------------------------------------

import CNDS

var touch = touchPosition()

var topScreen = PrintConsole()
var bottomScreen = PrintConsole()

videoSetMode(MODE_0_2D.rawValue)
videoSetModeSub(MODE_0_2D.rawValue)

vramSetBankA(VRAM_A_MAIN_BG)
vramSetBankC(VRAM_C_SUB_BG)

consoleInit(&topScreen, 3, BgType_Text4bpp, BgSize_T_256x256, 31, 0, true, true)
consoleInit(&bottomScreen, 3, BgType_Text4bpp, BgSize_T_256x256, 31, 0, false, true)

consoleSelect(&topScreen)
nds_puts("\n\n\tHello DS dev'rs\n")
nds_puts("\twww.drunkencoders.com\n")
nds_puts("\twww.devkitpro.org")

consoleSelect(&bottomScreen)

while pmMainLoop() {
	touchRead(&touch)

	nds_printf_2i("\u{1b}[10;0HTouch x = %04i, %04i\n", Int32(touch.rawx), Int32(touch.px))
	nds_printf_2i("Touch y = %04i, %04i\n", Int32(touch.rawy), Int32(touch.py))

	threadWaitForVBlank()
	scanKeys()

	if keysDown() & KEY_START != 0 { break }
}
