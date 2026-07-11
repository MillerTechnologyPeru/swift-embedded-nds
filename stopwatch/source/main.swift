//---------------------------------------------------------------------------------
//
//  Swift port of the libnds stopwatch example.
//
//  A timer is used as a stopwatch: A starts/pauses, B clears, START quits.
//
//---------------------------------------------------------------------------------

import NDS

enum TimerState {
	case stop, pause, running
}

Console.demoInit()

// the speed of the timer when using .div1024
let timerSpeed = Timer.busClock / 1024

var ticks: UInt32 = 0
var state: TimerState = .stop

while System.mainLoop {
	System.waitForVBlank()
	Console.clear()
	Keys.scan()
	let down = Keys.down

	if down.contains(.start) { break }

	if state == .running {
		ticks += UInt32(Timer.elapsed(0))
	}

	if down.contains(.a) {
		switch state {
		case .stop:
			Timer.start(0, divider: .div1024, reload: 0)
			state = .running
		case .pause:
			Timer.unpause(0)
			state = .running
		case .running:
			ticks += UInt32(Timer.pause(0))
			state = .pause
		}
	} else if down.contains(.b) {
		Timer.stop(0)
		ticks = 0
		state = .stop
	}

	Console.print("Press A to start and pause the \ntimer, B to clear the timer \nand start to quit the program.\n\n")
	Console.printf("ticks:  %u\n", Int32(bitPattern: ticks))
	Console.printf("second: %u.%03u\n",
	               Int32(bitPattern: ticks / timerSpeed),
	               Int32(bitPattern: ((ticks % timerSpeed) * 1000) / timerSpeed))
}

if state != .stop {
	Timer.stop(0)
}
