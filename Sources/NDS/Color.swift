//===----------------------------------------------------------------------===//
// Color.swift -- 15-bit BGR colors.
//
// The DS stores colors as 15-bit BGR555 (`u16`), one bit per component times 5,
// with the high bit used as an alpha/enable flag in some contexts. libnds
// exposes these only through the RGB15 / RGB5 / RGB8 / ARGB16 function-like
// macros, which the Swift importer drops -- so we reimplement them here as a
// value type.
//===----------------------------------------------------------------------===//

/// A 15-bit BGR555 color, the native pixel/palette format of the DS.
public struct Color: Equatable, RawRepresentable {
    /// The packed `u16` value (`0bA_BBBBB_GGGGG_RRRRR`).
    public var rawValue: UInt16

    @inline(__always)
    public init(rawValue: UInt16) { self.rawValue = rawValue }

    /// Build a color from 5-bit components (0...31), matching `RGB15`.
    @inline(__always)
    public init(r: UInt8, g: UInt8, b: UInt8) {
        rawValue = UInt16(r & 31) | (UInt16(g & 31) << 5) | (UInt16(b & 31) << 10)
    }

    /// Build a color from 8-bit components (0...255), matching `RGB8`.
    @inline(__always)
    public init(r8: UInt8, g8: UInt8, b8: UInt8) {
        self.init(r: r8 >> 3, g: g8 >> 3, b: b8 >> 3)
    }

    /// Build a color with the high (alpha/enable) bit, matching `ARGB16`.
    @inline(__always)
    public init(a: Bool, r: UInt8, g: UInt8, b: UInt8) {
        self.init(r: r, g: g, b: b)
        if a { rawValue |= 0x8000 }
    }

    public var red:   UInt8 { UInt8(rawValue & 31) }
    public var green: UInt8 { UInt8((rawValue >> 5) & 31) }
    public var blue:  UInt8 { UInt8((rawValue >> 10) & 31) }

    public static let black = Color(r: 0,  g: 0,  b: 0)
    public static let white = Color(r: 31, g: 31, b: 31)
    public static let red   = Color(r: 31, g: 0,  b: 0)
    public static let green = Color(r: 0,  g: 31, b: 0)
    public static let blue  = Color(r: 0,  g: 0,  b: 31)
}
