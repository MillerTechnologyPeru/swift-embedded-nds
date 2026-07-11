//===----------------------------------------------------------------------===//
// Rumble.swift -- the Slot-2 rumble pak.
//===----------------------------------------------------------------------===//

public enum Rumble {
    /// Whether a rumble pak is inserted in Slot-2 (`rumbleIsInserted`).
    @inline(__always) public static var isInserted: Bool { rumbleIsInserted() }
    /// Set the rumble motor on or off (`rumbleSet`).
    @inline(__always) public static func set(_ on: Bool) { rumbleSet(on) }
}
