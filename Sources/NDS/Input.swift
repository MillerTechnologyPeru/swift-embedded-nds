//===----------------------------------------------------------------------===//
// Input.swift -- keypad buttons.
//
// libnds reads the keypad into memory with scanKeys(), then keysDown/Held/Up
// return raw `u32` bitmasks. The individual bits are `#define`d integers
// (KEY_A ...), and KEY_TOUCH is `BIT(14)` which the importer drops. We model
// the buttons as a `Key` OptionSet so callers write `.contains(.start)` instead
// of masking magic numbers.
//===----------------------------------------------------------------------===//

/// A set of keypad buttons (a `KEY_*` bitmask).
public struct Key: OptionSet {
    public let rawValue: UInt32
    @inline(__always) public init(rawValue: UInt32) { self.rawValue = rawValue }

    public static let a      = Key(rawValue: 1 << 0)
    public static let b      = Key(rawValue: 1 << 1)
    public static let select = Key(rawValue: 1 << 2)
    public static let start  = Key(rawValue: 1 << 3)
    public static let right  = Key(rawValue: 1 << 4)
    public static let left   = Key(rawValue: 1 << 5)
    public static let up     = Key(rawValue: 1 << 6)
    public static let down   = Key(rawValue: 1 << 7)
    public static let r      = Key(rawValue: 1 << 8)
    public static let l      = Key(rawValue: 1 << 9)
    public static let x      = Key(rawValue: 1 << 10)
    public static let y      = Key(rawValue: 1 << 11)
    /// The lid/hinge sensor (`KEY_HINGE` / `KEY_LID`).
    public static let hinge  = Key(rawValue: 1 << 12)
    public static let debug  = Key(rawValue: 1 << 13)
    /// The touchscreen (`KEY_TOUCH` = `BIT(14)`, which the importer drops).
    public static let touch  = Key(rawValue: 1 << 14)
}

/// The keypad. Call `Keys.scan()` once per frame, then read `down`/`held`/`up`.
public enum Keys {
    /// Sample the hardware keypad into memory (`scanKeys`). Call once per frame.
    @inline(__always) public static func scan() { scanKeys() }

    /// Keys pressed this frame (edge). (`keysDown`)
    @inline(__always) public static var down: Key { Key(rawValue: keysDown()) }
    /// Keys currently held. (`keysHeld`)
    @inline(__always) public static var held: Key { Key(rawValue: keysHeld()) }
    /// Keys released this frame (edge). (`keysUp`)
    @inline(__always) public static var up: Key { Key(rawValue: keysUp()) }
    /// Raw current hardware state, ignoring edge tracking. (`keysCurrent`)
    @inline(__always) public static var current: Key { Key(rawValue: keysCurrent()) }
    /// Keys pressed this frame including auto-repeat. (`keysDownRepeat`)
    @inline(__always) public static var downRepeat: Key { Key(rawValue: keysDownRepeat()) }

    /// Configure auto-repeat: frames before repeat starts, then between repeats.
    @inline(__always) public static func setRepeat(delay: UInt8, period: UInt8) {
        keysSetRepeat(delay, period)
    }
}
