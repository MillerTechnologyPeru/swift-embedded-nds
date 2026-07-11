//===----------------------------------------------------------------------===//
// Bios.swift -- ARM BIOS SWI calls.
//
// Thin wrappers over the `swi*` software-interrupt helpers (hardware divide,
// sqrt, CRC16, halt/sleep, and the BIOS decompressors).
//===----------------------------------------------------------------------===//

public enum Bios {
    @inline(__always) public static func divide(_ numerator: Int32, by divisor: Int32) -> Int32 { swiDivide(numerator, divisor) }
    @inline(__always) public static func remainder(_ numerator: Int32, over divisor: Int32) -> Int32 { swiRemainder(numerator, divisor) }
    @inline(__always) public static func sqrt(_ value: Int32) -> Int32 { swiSqrt(value) }
    @inline(__always) public static func crc16(_ crc: UInt16, data: UnsafeMutableRawPointer, size: UInt32) -> UInt16 { swiCRC16(crc, data, size) }

    /// Busy-wait `duration` loop iterations (`swiDelay`).
    @inline(__always) public static func delay(_ duration: UInt32) { swiDelay(duration) }
    @inline(__always) public static var isDebugger: Bool { swiIsDebugger() != 0 }

    // MARK: BIOS decompressors (main RAM variants)

    @inline(__always) public static func decompressLZSS(from src: UnsafeRawPointer, to dst: UnsafeMutableRawPointer) {
        swiDecompressLZSSWram(src, dst)
    }
    @inline(__always) public static func decompressRLE(from src: UnsafeRawPointer, to dst: UnsafeMutableRawPointer) {
        swiDecompressRLEWram(src, dst)
    }
}
