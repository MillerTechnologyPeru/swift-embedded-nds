//===----------------------------------------------------------------------===//
// Touch.swift -- touchscreen reading.
//
// `touchPosition` is a typealias for calico's `TouchData` (px/py in pixels,
// rawx/rawy the 12-bit ADC values). It imports fine; we add a Swift-friendly
// read that returns the position and whether the screen is being touched.
//===----------------------------------------------------------------------===//

public enum Touch {
    /// Read the touchscreen. Returns the position and whether it is being
    /// touched (`touchRead`).
    @inline(__always)
    public static func read() -> (position: touchPosition, isTouched: Bool) {
        var pos = touchPosition()
        let touched = touchRead(&pos)
        return (pos, touched)
    }

    /// Read the touchscreen into an existing value, returning whether it is
    /// being touched (mirrors the C `touchRead(&pos)` signature).
    @inline(__always)
    public static func read(into pos: inout touchPosition) -> Bool {
        touchRead(&pos)
    }
}

public extension touchPosition {
    /// Touch position in screen pixels.
    var pixel: (x: UInt16, y: UInt16) { (px, py) }
    /// Raw 12-bit ADC position.
    var raw: (x: UInt16, y: UInt16) { (rawx, rawy) }
}
