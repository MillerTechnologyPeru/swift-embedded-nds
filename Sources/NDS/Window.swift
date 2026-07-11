//===----------------------------------------------------------------------===//
// Window.swift -- the hardware display windows (rectangular masks).
//===----------------------------------------------------------------------===//

public enum Window {
    /// A hardware display window (`WINDOW`).
    public enum ID {
        case window0, window1, object, outside
        @inline(__always) var c: WINDOW {
            switch self {
            case .window0: return WINDOW_0
            case .window1: return WINDOW_1
            case .object:  return WINDOW_OBJ
            case .outside: return WINDOW_OUT
            }
        }
    }

    @inline(__always) public static func enable(_ w: ID) { windowEnable(w.c) }
    @inline(__always) public static func disable(_ w: ID) { windowDisable(w.c) }
    @inline(__always) public static func enableSub(_ w: ID) { windowEnableSub(w.c) }
    @inline(__always) public static func disableSub(_ w: ID) { windowDisableSub(w.c) }

    /// Set a window's rectangular bounds on the main engine (`windowSetBounds`).
    @inline(__always) public static func setBounds(_ w: ID, left: UInt8, top: UInt8, right: UInt8, bottom: UInt8) {
        windowSetBounds(w.c, left, top, right, bottom)
    }
    @inline(__always) public static func setBoundsSub(_ w: ID, left: UInt8, top: UInt8, right: UInt8, bottom: UInt8) {
        windowSetBoundsSub(w.c, left, top, right, bottom)
    }

    /// Show a background layer inside/outside a window (`bgWindowEnable`).
    @inline(__always) public static func enableBackground(_ bg: Background, in w: ID) { bgWindowEnable(bg.id, w.c) }
    @inline(__always) public static func disableBackground(_ bg: Background, in w: ID) { bgWindowDisable(bg.id, w.c) }
    @inline(__always) public static func enableSprites(_ oam: OAM, in w: ID) { oamWindowEnable(oam.state, w.c) }
    @inline(__always) public static func disableSprites(_ oam: OAM, in w: ID) { oamWindowDisable(oam.state, w.c) }
}
