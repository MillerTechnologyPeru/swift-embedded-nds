//===----------------------------------------------------------------------===//
// Math.swift -- the trig lookup table and the hardware math (divide / sqrt).
//
// `sinLerp` / `cosLerp` etc. take a 16-bit angle where a full turn is 0x10000
// (so pi is 0x8000, quarter turn 0x4000) and return a 1.19.12-ish fixed value.
// The hardware divider/sqrt are exposed via libnds' `div*` / `sqrt*` helpers.
//===----------------------------------------------------------------------===//

/// Fixed-point trig and hardware math. Angles are 0...0xFFFF over a full turn.
public enum Math {

    // MARK: Trig LUT

    /// Sine of a 16-bit angle, as fixed point (`sinLerp`).
    @inline(__always) public static func sin(_ angle: Int16) -> Int16 { sinLerp(angle) }
    /// Cosine of a 16-bit angle, as fixed point (`cosLerp`).
    @inline(__always) public static func cos(_ angle: Int16) -> Int16 { cosLerp(angle) }
    /// Tangent of a 16-bit angle, as fixed point (`tanLerp`).
    @inline(__always) public static func tan(_ angle: Int16) -> Int32 { tanLerp(angle) }
    /// Arcsine (`asinLerp`).
    @inline(__always) public static func asin(_ value: Int16) -> Int16 { asinLerp(value) }
    /// Arccosine (`acosLerp`).
    @inline(__always) public static func acos(_ value: Int16) -> Int16 { acosLerp(value) }

    /// Fixed-point atan2 via the shim (LUT + hardware divider); returns [0,0x8000)
    /// where pi is 0x4000 (`nds_atan2_lerp`).
    @inline(__always) public static func atan2(x: Int32, y: Int32) -> UInt32 { nds_atan2_lerp(x, y) }

    // MARK: f32 (20.12) fixed-point math (hardware divider)

    @inline(__always) public static func divf32(_ num: Int32, _ den: Int32) -> Int32 { CNDS.divf32(num, den) }
    @inline(__always) public static func mulf32(_ a: Int32, _ b: Int32) -> Int32 { CNDS.mulf32(a, b) }
    @inline(__always) public static func sqrtf32(_ a: Int32) -> Int32 { CNDS.sqrtf32(a) }

    // MARK: Integer hardware divide / sqrt

    @inline(__always) public static func div(_ num: Int32, _ den: Int32) -> Int32 { div32(num, den) }
    @inline(__always) public static func mod(_ num: Int32, _ den: Int32) -> Int32 { mod32(num, den) }
    @inline(__always) public static func sqrt(_ a: Int32) -> UInt32 { sqrt32(a) }

    // MARK: f32 vector helpers

    @inline(__always) public static func cross(_ a: UnsafeMutablePointer<Int32>, _ b: UnsafeMutablePointer<Int32>, result: UnsafeMutablePointer<Int32>) {
        crossf32(a, b, result)
    }
    @inline(__always) public static func dot(_ a: UnsafeMutablePointer<Int32>, _ b: UnsafeMutablePointer<Int32>) -> Int32 { dotf32(a, b) }
    @inline(__always) public static func normalize(_ a: UnsafeMutablePointer<Int32>) { normalizef32(a) }
}
