//---------------------------------------------------------------------------------
//
//  Swift port of the libnds stopwatch example.
//
//  A timer is used as a stopwatch: A starts/pauses, B clears, START quits.
//
//---------------------------------------------------------------------------------

import CNDS

enum TimerState {
	case stop, pause, running
}

consoleDemoInit()

// the speed of the timer when using ClockDivider_1024
let timerSpeed = nds_bus_clock() / 1024

var ticks: UInt32 = 0
var state: TimerState = .stop

while pmMainLoop() {
	threadWaitForVBlank()
	consoleClear()
	scanKeys()
	let down = keysDown()

	if down & KEY_START != 0 { break }

	if state == .running {
		ticks += UInt32(timerElapsed(0))
	}

	if down & KEY_A != 0 {
		switch state {
		case .stop:
			timerStart(0, ClockDivider_1024, 0, nil)
			state = .running
		case .pause:
			timerUnpause(0)
			state = .running
		case .running:
			ticks += UInt32(timerPause(0))
			state = .pause
		}
	} else if down & KEY_B != 0 {
		_ = timerStop(0)
		ticks = 0
		state = .stop
	}

	nds_puts("Press A to start and pause the \ntimer, B to clear the timer \nand start to quit the program.\n\n")
	nds_printf_1i("ticks:  %u\n", Int32(bitPattern: ticks))
	nds_printf_2i("second: %u.%03u\n",
	              Int32(bitPattern: ticks / timerSpeed),
	              Int32(bitPattern: ((ticks % timerSpeed) * 1000) / timerSpeed))
}

if state != .stop {
	_ = timerStop(0)
}
