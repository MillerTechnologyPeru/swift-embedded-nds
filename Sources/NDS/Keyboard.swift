//===----------------------------------------------------------------------===//
// Keyboard.swift -- the on-screen keyboard.
//
// `keyboardDemoInit` sets up the default keyboard on the sub screen. Poll with
// `update()` (returns the pressed character or -1), or read a whole line with
// `getString`. The per-key callback is set directly on the `Keyboard` struct's
// `OnKeyPressed` field (a non-capturing function bridges to the C pointer).
//===----------------------------------------------------------------------===//

public enum OnScreenKeyboard {
    /// Initialize the default on-screen keyboard (`keyboardDemoInit`).
    @discardableResult
    @inline(__always) public static func demoInit() -> UnsafeMutablePointer<Keyboard>? { keyboardDemoInit() }

    /// Full `keyboardInit`: bind the keyboard to a background layer/engine.
    @discardableResult
    @inline(__always)
    public static func initialize(_ keyboard: UnsafeMutablePointer<Keyboard>?, layer: Int32,
                                  kind: Background.Kind, size: BgSize, mapBase: Int32, tileBase: Int32,
                                  mainDisplay: Bool, loadGraphics: Bool = true) -> UnsafeMutablePointer<Keyboard>? {
        keyboardInit(keyboard, layer, kind.c, size, mapBase, tileBase, mainDisplay, loadGraphics)
    }

    @inline(__always) public static var current: UnsafeMutablePointer<Keyboard>? { keyboardGetDefault() }
    @inline(__always) public static func show() { keyboardShow() }
    @inline(__always) public static func hide() { keyboardHide() }

    /// Advance keyboard input, returning the pressed character or -1 (`keyboardUpdate`).
    @inline(__always) public static func update() -> Int32 { keyboardUpdate() }
    /// Block for a single character (`keyboardGetChar`).
    @inline(__always) public static func getChar() -> Int32 { keyboardGetChar() }
    /// Read a string into `buffer` (`keyboardGetString`).
    @inline(__always) public static func getString(into buffer: UnsafeMutablePointer<CChar>, maxLength: Int32) {
        keyboardGetString(buffer, maxLength)
    }
}
