//===----------------------------------------------------------------------===//
// Cache.swift -- ARM9 instruction / data cache maintenance.
//
// Needed when sharing memory with the DMA/geometry hardware: flush the data
// cache so writes reach RAM, or invalidate before reading hardware-written data.
//===----------------------------------------------------------------------===//

public enum Cache {
    // Instruction cache
    @inline(__always) public static func invalidateInstructionCache() { IC_InvalidateAll() }
    @inline(__always) public static func invalidateInstructionRange(_ base: UnsafeRawPointer, size: UInt32) { IC_InvalidateRange(base, size) }

    // Data cache
    @inline(__always) public static func flushDataCache() { DC_FlushAll() }
    @inline(__always) public static func flushDataRange(_ base: UnsafeRawPointer, size: UInt32) { DC_FlushRange(base, size) }
    @inline(__always) public static func invalidateDataRange(_ base: UnsafeRawPointer, size: UInt32) { DC_InvalidateRange(base, size) }
}
