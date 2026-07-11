//===----------------------------------------------------------------------===//
// Video.swift -- display control and VRAM bank mapping.
//
// Wraps libnds' `video*` / `vram*` entry points. The VRAM bank-mode enums
// (`VRAM_A_TYPE` ... `VRAM_I_TYPE`) import fine from CNDS and are passed through
// directly; only the display mode gets a Swift enum so callers stop writing
// `videoSetMode(MODE_0_2D.rawValue)`.
//===----------------------------------------------------------------------===//

/// Display control for the two 2D engines and VRAM bank mapping.
public enum Video {

    /// A display mode for one of the 2D engines. Mapped to the libnds `MODE_*`
    /// constants so the exact bit values stay authoritative.
    public enum Mode {
        case mode0_2D, mode1_2D, mode2_2D, mode3_2D, mode4_2D, mode5_2D, mode6_2D
        case mode0_3D, mode1_3D, mode2_3D, mode3_3D, mode4_3D, mode5_3D, mode6_3D
        case fifo, fb0, fb1, fb2, fb3

        @inline(__always) var rawValue: UInt32 {
            switch self {
            case .mode0_2D: return MODE_0_2D.rawValue
            case .mode1_2D: return MODE_1_2D.rawValue
            case .mode2_2D: return MODE_2_2D.rawValue
            case .mode3_2D: return MODE_3_2D.rawValue
            case .mode4_2D: return MODE_4_2D.rawValue
            case .mode5_2D: return MODE_5_2D.rawValue
            case .mode6_2D: return MODE_6_2D.rawValue
            case .mode0_3D: return MODE_0_3D.rawValue
            case .mode1_3D: return MODE_1_3D.rawValue
            case .mode2_3D: return MODE_2_3D.rawValue
            case .mode3_3D: return MODE_3_3D.rawValue
            case .mode4_3D: return MODE_4_3D.rawValue
            case .mode5_3D: return MODE_5_3D.rawValue
            case .mode6_3D: return MODE_6_3D.rawValue
            case .fifo:     return MODE_FIFO.rawValue
            case .fb0:      return MODE_FB0.rawValue
            case .fb1:      return MODE_FB1.rawValue
            case .fb2:      return MODE_FB2.rawValue
            case .fb3:      return MODE_FB3.rawValue
            }
        }
    }

    /// Which physical screen(s) an operation applies to.
    public enum Screen: Int32 {
        case main = 1, sub = 2, both = 3
    }

    // MARK: Mode

    @inline(__always) public static func setMode(_ mode: Mode) { videoSetMode(mode.rawValue) }
    @inline(__always) public static func setModeSub(_ mode: Mode) { videoSetModeSub(mode.rawValue) }
    /// Write a raw `REG_DISPCNT` value, for modes/flag combinations not covered by
    /// `Mode` (e.g. `Video.setMode(raw: 0)` to blank the engine).
    @inline(__always) public static func setMode(raw value: UInt32) { videoSetMode(value) }
    @inline(__always) public static func setModeSub(raw value: UInt32) { videoSetModeSub(value) }
    @inline(__always) public static var mode: Int32 { videoGetMode() }
    @inline(__always) public static var modeSub: Int32 { videoGetModeSub() }
    @inline(__always) public static var is3DEnabled: Bool { video3DEnabled() }

    // MARK: Background layer enable

    @inline(__always) public static func enableBg(_ layer: Int32) { videoBgEnable(layer) }
    @inline(__always) public static func disableBg(_ layer: Int32) { videoBgDisable(layer) }
    @inline(__always) public static func enableBgSub(_ layer: Int32) { videoBgEnableSub(layer) }
    @inline(__always) public static func disableBgSub(_ layer: Int32) { videoBgDisableSub(layer) }

    // MARK: Brightness / backdrop

    /// Set master brightness: `-16` = black, `0` = normal, `16` = white.
    @inline(__always) public static func setBrightness(_ screen: Screen, _ level: Int32) {
        CNDS.setBrightness(screen.rawValue, level)
    }

    @inline(__always) public static func setBackdrop(_ color: Color) {
        setBackdropColor(color.rawValue)
    }
    @inline(__always) public static func setBackdropSub(_ color: Color) {
        setBackdropColorSub(color.rawValue)
    }

    // MARK: VRAM bank mapping
    //
    // The bank-mode enums import from CNDS with their full C names, e.g.
    // `.setBankA(VRAM_A_MAIN_BG)`. These are thin renames of `vramSetBankX`.

    @inline(__always) public static func setBankA(_ mode: VRAM_A_TYPE) { vramSetBankA(mode) }
    @inline(__always) public static func setBankB(_ mode: VRAM_B_TYPE) { vramSetBankB(mode) }
    @inline(__always) public static func setBankC(_ mode: VRAM_C_TYPE) { vramSetBankC(mode) }
    @inline(__always) public static func setBankD(_ mode: VRAM_D_TYPE) { vramSetBankD(mode) }
    @inline(__always) public static func setBankE(_ mode: VRAM_E_TYPE) { vramSetBankE(mode) }
    @inline(__always) public static func setBankF(_ mode: VRAM_F_TYPE) { vramSetBankF(mode) }
    @inline(__always) public static func setBankG(_ mode: VRAM_G_TYPE) { vramSetBankG(mode) }
    @inline(__always) public static func setBankH(_ mode: VRAM_H_TYPE) { vramSetBankH(mode) }
    @inline(__always) public static func setBankI(_ mode: VRAM_I_TYPE) { vramSetBankI(mode) }

    /// Map the four primary banks (A-D) in one call (`vramSetPrimaryBanks`).
    @inline(__always) public static func setPrimaryBanks(_ a: VRAM_A_TYPE, _ b: VRAM_B_TYPE, _ c: VRAM_C_TYPE, _ d: VRAM_D_TYPE) {
        vramSetPrimaryBanks(a, b, c, d)
    }
    /// Map banks E, F and G in one call (`vramSetBanks_EFG`).
    @inline(__always) public static func setBanksEFG(_ e: VRAM_E_TYPE, _ f: VRAM_F_TYPE, _ g: VRAM_G_TYPE) {
        vramSetBanks_EFG(e, f, g)
    }

    /// Restore the primary banks (A-D) from a saved value (`vramRestorePrimaryBanks`).
    @inline(__always) public static func restorePrimaryBanks(_ saved: UInt32) {
        vramRestorePrimaryBanks(saved)
    }
    @inline(__always) public static func restoreBanksEFG(_ saved: UInt32) {
        vramRestoreBanks_EFG(saved)
    }
}
