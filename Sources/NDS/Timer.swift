//===----------------------------------------------------------------------===//
// Timer.swift -- the four hardware timers + the CPU cycle counter.
//
// `timerStart(timer, divider, ticks, callback)` starts a timer; the reload
// `ticks` for a target frequency come from the TIMER_FREQ_* macros (which the
// importer drops -- the shim exposes `nds_timer_freq_1024` / `nds_bus_clock`).
//===----------------------------------------------------------------------===//

/// The four hardware timer channels (0...3) and the CPU cycle counter.
public enum Timer {

    /// The timer's clock prescaler (`ClockDivider`).
    public enum Divider {
        case div1, div64, div256, div1024
        @inline(__always) var c: ClockDivider {
            switch self {
            case .div1:    return ClockDivider_1
            case .div64:   return ClockDivider_64
            case .div256:  return ClockDivider_256
            case .div1024: return ClockDivider_1024
            }
        }
    }

    /// The timer base frequency in Hz (`BUS_CLOCK`).
    @inline(__always) public static var busClock: UInt32 { nds_bus_clock() }

    /// Reload value for a `/1024`-prescaled timer targeting `hz` (`TIMER_FREQ_1024`).
    @inline(__always) public static func ticksForFrequency1024(_ hz: Int32) -> UInt16 {
        nds_timer_freq_1024(hz)
    }

    /// Start timer `channel` with the given prescaler and reload value, optionally
    /// firing `callback` (a non-capturing function) on each overflow (`timerStart`).
    @inline(__always)
    public static func start(_ channel: UInt32, divider: Divider, reload: UInt16,
                             callback: (@convention(c) () -> Void)? = nil) {
        timerStart(channel, divider.c, reload, callback)
    }

    /// Ticks elapsed since the last call (`timerElapsed`).
    @inline(__always) public static func elapsed(_ channel: UInt32) -> UInt16 { timerElapsed(channel) }
    /// Current raw counter value (`timerTick`).
    @inline(__always) public static func tick(_ channel: UInt32) -> UInt16 { timerTick(channel) }
    /// Pause the timer, returning its current value (`timerPause`).
    @discardableResult
    @inline(__always) public static func pause(_ channel: UInt32) -> UInt16 { timerPause(channel) }
    @inline(__always) public static func unpause(_ channel: UInt32) { timerUnpause(channel) }
    /// Stop the timer, returning its final value (`timerStop`).
    @discardableResult
    @inline(__always) public static func stop(_ channel: UInt32) -> UInt16 { timerStop(channel) }

    @inline(__always) public static func ticksToMicroseconds(_ ticks: UInt32) -> UInt32 { timerTicks2usec(ticks) }
    @inline(__always) public static func ticksToMilliseconds(_ ticks: UInt32) -> UInt32 { timerTicks2msec(ticks) }
}

/// The CPU timing counter (uses two chained timers) for benchmarking.
public enum CPUTiming {
    @inline(__always) public static func start() { cpuStartTiming(0) }
    @inline(__always) public static func get() -> UInt32 { cpuGetTiming() }
    @inline(__always) public static func end() -> UInt32 { cpuEndTiming() }
}
