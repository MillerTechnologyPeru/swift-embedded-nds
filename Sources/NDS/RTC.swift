//===----------------------------------------------------------------------===//
// RTC.swift -- the real-time clock.
//
// The shim reads calico's RTC into plain integer out-parameters
// (`nds_rtc_read`); this surfaces it as a Swift value.
//===----------------------------------------------------------------------===//

/// A wall-clock date/time read from the hardware RTC.
public struct DateTime {
    public var year: Int32     // full year, e.g. 2026
    public var month: Int32    // 1...12
    public var day: Int32      // 1...31
    public var hour: Int32     // 0...23
    public var minute: Int32   // 0...59
    public var second: Int32   // 0...59
}

public enum RTC {
    /// Read the current date/time from the real-time clock (`nds_rtc_read`).
    @inline(__always) public static func now() -> DateTime {
        var y: Int32 = 0, mo: Int32 = 0, d: Int32 = 0, h: Int32 = 0, mi: Int32 = 0, s: Int32 = 0
        nds_rtc_read(&y, &mo, &d, &h, &mi, &s)
        return DateTime(year: y, month: mo, day: d, hour: h, minute: mi, second: s)
    }
}
