//===----------------------------------------------------------------------===//
// System.swift -- power, the main loop, VBlank sync, and LCD assignment.
//
// The modern (calico-based) runtime drives the program from `pmMainLoop()` and
// synchronizes with `threadWaitForVBlank()` (the classic `swiWaitForVBlank` is
// now just a macro alias for it).
//===----------------------------------------------------------------------===//

public enum System {
    /// Whether the program should keep running. The idiomatic main loop is
    /// `while System.mainLoop { ... }` (`pmMainLoop`).
    @inline(__always) public static var mainLoop: Bool { pmMainLoop() }

    /// Block until the next vertical-blank interrupt (`threadWaitForVBlank`,
    /// a.k.a. `swiWaitForVBlank`). The standard once-per-frame sync point.
    @inline(__always) public static func waitForVBlank() { threadWaitForVBlank() }

    // MARK: Power

    /// Turn on the given hardware subsystems (`powerOn`, `POWER_*` bits).
    @inline(__always) public static func powerOn(_ bits: Int32) { CNDS.powerOn(bits) }
    /// Turn off the given hardware subsystems (`powerOff`).
    @inline(__always) public static func powerOff(_ bits: Int32) { CNDS.powerOff(bits) }

    /// Switch the ARM9 between the standard and doubled CPU clock (`setCpuClock`).
    @discardableResult
    @inline(__always) public static func setCpuClock(fast: Bool) -> Bool { CNDS.setCpuClock(fast) }

    // MARK: LCD assignment

    /// Swap which physical screen each engine drives (`lcdSwap`).
    @inline(__always) public static func lcdSwap() { CNDS.lcdSwap() }
    /// Put the main engine on the top screen (`lcdMainOnTop`).
    @inline(__always) public static func lcdMainOnTop() { CNDS.lcdMainOnTop() }
    /// Put the main engine on the bottom screen (`lcdMainOnBottom`).
    @inline(__always) public static func lcdMainOnBottom() { CNDS.lcdMainOnBottom() }

    // MARK: Firmware

    @inline(__always) public static func readFirmware(address: UInt32, into buffer: UnsafeMutableRawPointer, length: UInt32) {
        CNDS.readFirmware(address, buffer, length)
    }
}
