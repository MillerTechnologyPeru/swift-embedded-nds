//---------------------------------------------------------------------------------
//
//  Swift port of the libnds timercallback example.
//
//  A hardware timer fires an IRQ callback 5 times a second, toggling a PSG tone
//  between paused and playing.
//
//---------------------------------------------------------------------------------

import CNDS

private var play = true
private var trigger = false   // set from the IRQ callback, polled in main

// Timer callback. This runs in IRQ mode -- be careful!
// A non-capturing top-level function bridges to the C VoidFn pointer.
private func timerCallBack() {
	play = !play
	trigger = true
}

consoleDemoInit()
nds_puts("Timer callback demo\n")

soundEnable()
let channel = soundPlayPSG(SoundDuty_50, 10000, 127, 64)

// calls timerCallBack 5 times per second (TIMER_FREQ_1024(5) via the shim).
timerStart(0, ClockDivider_1024, nds_timer_freq_1024(5), timerCallBack)

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()

	if keysDown() & KEY_START != 0 { break }

	if trigger {
		trigger = false
		if play {
			soundResume(channel)
		} else {
			soundPause(channel)
		}
	}
}
