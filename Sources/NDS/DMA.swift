//===----------------------------------------------------------------------===//
// DMA.swift -- hardware DMA copy / fill.
//
// Thin wrappers over libnds' `dmaCopy*` / `dmaFill*` inline helpers. Channel 3
// is the conventional general-purpose channel used by the bare `dmaCopy`/
// `dmaFill` convenience calls.
//===----------------------------------------------------------------------===//

/// Hardware DMA transfers. `size` is in bytes.
public enum DMA {
    /// Copy `size` bytes via channel 3, choosing word/halfword width (`dmaCopy`).
    @inline(__always) public static func copy(from src: UnsafeRawPointer, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaCopy(src, dest, size)
    }

    @inline(__always) public static func copyWords(channel: UInt8, from src: UnsafeRawPointer, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaCopyWords(channel, src, dest, size)
    }
    @inline(__always) public static func copyHalfWords(channel: UInt8, from src: UnsafeRawPointer, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaCopyHalfWords(channel, src, dest, size)
    }

    /// Non-blocking variants -- return immediately; poll `isBusy`.
    @inline(__always) public static func copyAsync(from src: UnsafeRawPointer, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaCopyAsynch(src, dest, size)
    }
    @inline(__always) public static func copyWordsAsync(channel: UInt8, from src: UnsafeRawPointer, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaCopyWordsAsynch(channel, src, dest, size)
    }
    @inline(__always) public static func copyHalfWordsAsync(channel: UInt8, from src: UnsafeRawPointer, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaCopyHalfWordsAsynch(channel, src, dest, size)
    }

    /// Fill `size` bytes of `dest` with a repeated 32-bit value (`dmaFillWords`).
    @inline(__always) public static func fillWords(_ value: UInt32, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaFillWords(value, dest, size)
    }
    /// Fill `size` bytes of `dest` with a repeated 16-bit value (`dmaFillHalfWords`).
    @inline(__always) public static func fillHalfWords(_ value: UInt16, to dest: UnsafeMutableRawPointer, size: UInt32) {
        dmaFillHalfWords(value, dest, size)
    }

    /// Whether the given DMA channel is still transferring (`dmaBusy`).
    @inline(__always) public static func isBusy(_ channel: UInt8) -> Bool { dmaBusy(channel) != 0 }
}
