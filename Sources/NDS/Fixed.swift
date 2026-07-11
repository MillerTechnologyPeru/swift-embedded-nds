//===----------------------------------------------------------------------===//
// Fixed.swift -- fixed-point conversions for the 3D geometry engine.
//
// The GL/geometry engine uses several fixed-point formats. libnds exposes the
// conversions only as function-like macros (inttov16, floattof32, ...), which
// the Swift importer drops, so each 3D example currently redefines them. They
// are centralized here as free functions matching the C names (the `v16`, `t16`
// and `f32` types themselves import fine from CNDS as Int16/Int16/Int32).
//===----------------------------------------------------------------------===//

// MARK: - v16: vertex, 4.12 signed fixed point

/// Convert an integer to `v16` (`inttov16`).
@inline(__always) public func inttov16(_ n: Int32) -> v16 { v16(truncatingIfNeeded: n << 12) }
/// Convert a float to `v16` (`floattov16`).
@inline(__always) public func floattov16(_ n: Float) -> v16 { v16(n * Float(1 << 12)) }

/// Pack two `v16` values into a 32-bit `VERTEX_PACK`.
@inline(__always) public func VERTEX_PACK(_ x: v16, _ y: v16) -> UInt32 {
    (UInt32(bitPattern: Int32(x)) & 0xFFFF) | (UInt32(bitPattern: Int32(y)) << 16)
}

// MARK: - t16: texture coordinate, 12.4 fixed point

/// Convert an integer to `t16` (`inttot16`).
@inline(__always) public func inttot16(_ n: Int32) -> t16 { t16(truncatingIfNeeded: n << 4) }
/// Convert a float to `t16` (`floattot16`).
@inline(__always) public func floattot16(_ n: Float) -> t16 { t16(n * Float(1 << 4)) }

/// Pack two `t16` texture coordinates into a 32-bit `TEXTURE_PACK`.
@inline(__always) public func TEXTURE_PACK(_ u: t16, _ v: t16) -> UInt32 {
    (UInt32(bitPattern: Int32(u)) & 0xFFFF) | (UInt32(bitPattern: Int32(v)) << 16)
}

// MARK: - f32: 20.12 signed fixed point (matrices, cameras, coordinates)

/// Convert an integer to `f32` (`inttof32`).
@inline(__always) public func inttof32(_ n: Int32) -> Int32 { n << 12 }
/// Convert a float to `f32` (`floattof32`).
@inline(__always) public func floattof32(_ n: Float) -> Int32 { Int32(n * Float(1 << 12)) }
/// Convert an `f32` back to a float (`f32tofloat`).
@inline(__always) public func f32tofloat(_ n: Int32) -> Float { Float(n) / Float(1 << 12) }

// MARK: - v10: normal, .10 signed fixed point

/// Convert a float to `v10` (`floattov10`).
@inline(__always) public func floattov10(_ n: Float) -> v10 {
    n > 0.998 ? 0x1FF : v10(n * Float(1 << 9))
}

/// Pack three `v10` normal components into a 32-bit `NORMAL_PACK`.
@inline(__always) public func NORMAL_PACK(_ x: v10, _ y: v10, _ z: v10) -> UInt32 {
    (UInt32(bitPattern: Int32(x)) & 0x3FF)
        | ((UInt32(bitPattern: Int32(y)) & 0x3FF) << 10)
        | (UInt32(bitPattern: Int32(z)) << 20)
}
