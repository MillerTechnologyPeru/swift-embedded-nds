//===----------------------------------------------------------------------===//
// Filesystem.swift -- libfat (SD / flashcart) access.
//
// libfat is variadic-stdio heavy, so the shim provides fixed-arity helpers:
// mount the default filesystem, then write a buffer to a file.
//===----------------------------------------------------------------------===//

public enum Filesystem {
    /// Mount the default filesystem (SD card / flashcart). Returns true on
    /// success (`nds_fat_init` -> `fatInitDefault`).
    @discardableResult
    @inline(__always) public static func initialize() -> Bool { nds_fat_init() != 0 }

    /// Write `data` (of `length` bytes) to a file, replacing it. Returns true on
    /// success (`nds_write_file`, libfat-backed stdio).
    @discardableResult
    @inline(__always)
    public static func write(_ data: UnsafeRawPointer, length: UInt32, to path: UnsafePointer<CChar>) -> Bool {
        nds_write_file(path, data, length) != 0
    }

    /// Read a line from stdin (the on-screen keyboard), stripping the newline.
    /// Returns the length, or -1 on EOF (`nds_read_line`).
    @inline(__always)
    public static func readLine(into buffer: UnsafeMutablePointer<CChar>, size: Int32) -> Int32 {
        nds_read_line(buffer, size)
    }
}
