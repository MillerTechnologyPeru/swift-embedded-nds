//---------------------------------------------------------------------------------
//
//  Swift port of the libnds timercallback example.
//
//  A hardware timer fires an IRQ callback 5 times a second, toggling a PSG tone
//  between paused and playing.
//
//---------------------------------------------------------------------------------

import NDS

private var play = true
private var trigger = false   // set from the IRQ callback, polled in main

// Timer callback. This runs in IRQ mode -- be careful!
// A non-capturing top-level function bridges to the C VoidFn pointer.
private func timerCallBack() {
	play = !play
	trigger = true
}

Console.demoInit()
Console.print("Timer callback demo\n")

Sound.enable()
let channel = Sound.playPSG(duty: .d50, frequency: 10000)

// calls timerCallBack 5 times per second.
Timer.start(0, divider: .div1024, reload: Timer.ticksForFrequency1024(5), callback: timerCallBack)

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()

	if Keys.down.contains(.start) { break }

	if trigger {
		trigger = false
		if play {
			Sound.resume(channel)
		} else {
			Sound.pause(channel)
		}
	}
}
