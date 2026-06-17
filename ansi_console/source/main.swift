//---------------------------------------------------------------------------------
//
//  Demo of ANSI escape sequences -- Swift port of the libnds ansi_console example.
//
//---------------------------------------------------------------------------------

import CNDS

consoleDemoInit()

// ansi escape sequence to clear screen and home cursor:  \x1b[2J
nds_puts("\u{1b}[2J")

// ansi escape sequence to set print co-ordinates:        \x1b[line;columnH
nds_puts("\u{1b}[10;10HHello World!")

// ansi escape sequence to move cursor up:                \x1b[linesA
nds_puts("\u{1b}[10ALine 0")

// ansi escape sequence to move cursor left:              \x1b[columnsD
nds_puts("\u{1b}[28DColumn 0")

// ansi escape sequence to move cursor down:              \x1b[linesB
nds_puts("\u{1b}[19BLine 19")

// ansi escape sequence to move cursor right:             \x1b[columnsC
nds_puts("\u{1b}[5CColumn 20")

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
