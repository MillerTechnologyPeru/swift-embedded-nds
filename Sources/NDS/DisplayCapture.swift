//===----------------------------------------------------------------------===//
// DisplayCapture.swift -- the display-capture unit (motion blur, dual-screen 3D).
//
// The capture registers (REG_DISPCAPCNT + DCAP_* macros) are macro-only, so the
// shim exposes fixed operations: composite-with-feedback motion blur, and full-
// screen capture into a VRAM bank (used to mirror the 3D scene to both screens).
// The FIFO packed-command ids let you hand-build display lists.
//===----------------------------------------------------------------------===//

/// Motion blur via the display-capture unit's blend-with-feedback mode.
public enum MotionBlur {
    /// Configure the capture blend once (`nds_motion_blur_setup`).
    @inline(__always) public static func setup() { nds_motion_blur_setup() }
    /// Display the composited-from-VRAM (blurred) image (`nds_motion_blur_enable`).
    @inline(__always) public static func enable() { nds_motion_blur_enable() }
    /// Display the normal layer composition (`nds_motion_blur_disable`).
    @inline(__always) public static func disable() { nds_motion_blur_disable() }
    /// Re-arm the capture; call once per frame (`nds_motion_blur_continue`).
    @inline(__always) public static func `continue`() { nds_motion_blur_continue() }
}

/// Full-screen display capture into a VRAM bank.
public enum DisplayCapture {
    /// Whether a capture is currently in progress (`nds_dispcap_busy`).
    @inline(__always) public static var isBusy: Bool { nds_dispcap_busy() != 0 }
    /// Capture this frame to the given VRAM bank (`nds_dispcap_to_bank`).
    @inline(__always) public static func toBank(_ bank: Int32) { nds_dispcap_to_bank(bank) }
}

/// Packed geometry-FIFO command ids for hand-built display lists.
public enum FIFOCommand {
    @inline(__always) public static var begin: UInt8 { nds_fifo_begin() }
    @inline(__always) public static var color: UInt8 { nds_fifo_color() }
    @inline(__always) public static var vertex16: UInt8 { nds_fifo_vertex16() }
    @inline(__always) public static var end: UInt8 { nds_fifo_end() }
}
