//===----------------------------------------------------------------------===//
// Background.swift -- the 2D tiled / bitmap background layers.
//
// `bgInit` returns an integer background id; the other `bg*` calls take that id.
// We wrap that as a `Background` value type with methods, plus a `Kind` enum for
// the six `BgType` values. `BgSize` has many cases and is passed through as the
// imported C enum (its names, e.g. `BgSize_T_256x256`, are already clear).
//===----------------------------------------------------------------------===//

/// A 2D background layer, identified by the id returned from `bgInit`.
public struct Background {
    /// The libnds background id.
    public let id: Int32

    /// The kind of background (`BgType`).
    public enum Kind {
        case text8bpp, text4bpp, rotation, exRotation, bmp8, bmp16
        @inline(__always) var c: BgType {
            switch self {
            case .text8bpp:   return BgType_Text8bpp
            case .text4bpp:   return BgType_Text4bpp
            case .rotation:   return BgType_Rotation
            case .exRotation: return BgType_ExRotation
            case .bmp8:       return BgType_Bmp8
            case .bmp16:      return BgType_Bmp16
            }
        }
    }

    @inline(__always) public init(id: Int32) { self.id = id }

    /// Initialize a background on the main engine (`bgInit`).
    @inline(__always)
    public static func main(layer: Int32, kind: Kind, size: BgSize, mapBase: Int32, tileBase: Int32) -> Background {
        Background(id: bgInit(layer, kind.c, size, mapBase, tileBase))
    }

    /// Initialize a background on the sub engine (`bgInitSub`).
    @inline(__always)
    public static func sub(layer: Int32, kind: Kind, size: BgSize, mapBase: Int32, tileBase: Int32) -> Background {
        Background(id: bgInitSub(layer, kind.c, size, mapBase, tileBase))
    }

    /// Commit affine/priority changes to hardware; call once per frame (`bgUpdate`).
    @inline(__always) public static func update() { bgUpdate() }

    /// Enable extended background palettes on the main engine (`bgExtPaletteEnable`).
    @inline(__always) public static func enableExtPalette() { bgExtPaletteEnable() }
    /// Enable extended background palettes on the sub engine (`bgExtPaletteEnableSub`).
    @inline(__always) public static func enableExtPaletteSub() { bgExtPaletteEnableSub() }
    @inline(__always) public static func disableExtPalette() { bgExtPaletteDisable() }
    @inline(__always) public static func disableExtPaletteSub() { bgExtPaletteDisableSub() }

    // MARK: Pointers into VRAM

    /// The map (tile-index) memory for this background (`bgGetMapPtr`).
    @inline(__always) public var mapPointer: UnsafeMutablePointer<UInt16>? { bgGetMapPtr(id) }
    /// The tile/bitmap graphics memory for this background (`bgGetGfxPtr`).
    @inline(__always) public var gfxPointer: UnsafeMutablePointer<UInt16>? { bgGetGfxPtr(id) }

    // MARK: Scroll / visibility

    @inline(__always) public func setScroll(x: Int32, y: Int32) { bgSetScroll(id, x, y) }
    @inline(__always) public func scroll(dx: Int32, dy: Int32) { bgScroll(id, dx, dy) }
    @inline(__always) public func show() { bgShow(id) }
    @inline(__always) public func hide() { bgHide(id) }
    @inline(__always) public var isText: Bool { bgIsText(id) }

    // MARK: Bases / priority

    @inline(__always) public var priority: Int32 {
        get { bgGetPriority(id) }
        nonmutating set { bgSetPriority(id, UInt32(newValue)) }
    }
    @inline(__always) public var mapBase: Int32 {
        get { bgGetMapBase(id) }
        nonmutating set { bgSetMapBase(id, UInt32(newValue)) }
    }
    @inline(__always) public var tileBase: Int32 {
        get { bgGetTileBase(id) }
        nonmutating set { bgSetTileBase(id, UInt32(newValue)) }
    }

    // MARK: Affine (rotation / scale backgrounds)

    @inline(__always) public func setRotate(angle: Int32) { bgSetRotate(id, angle) }
    @inline(__always) public func rotate(angle: Int32) { bgRotate(id, angle) }
    @inline(__always) public func setRotateScale(angle: Int32, sx: Int32, sy: Int32) { bgSetRotateScale(id, angle, sx, sy) }
    @inline(__always) public func setScale(sx: Int32, sy: Int32) { bgSetScale(id, sx, sy) }
    @inline(__always) public func setCenter(x: Int32, y: Int32) { bgSetCenter(id, x, y) }
    @inline(__always) public func wrap(_ on: Bool) { on ? bgWrapOn(id) : bgWrapOff(id) }

    /// Set / clear raw bits in this background's control register
    /// (`bgSetControlBits` / `bgClearControlBits`), e.g. the wrap-enable bit.
    @inline(__always) public func setControlBits(_ bits: UInt16) { _ = bgSetControlBits(id, bits) }
    @inline(__always) public func clearControlBits(_ bits: UInt16) { bgClearControlBits(id, bits) }
    @inline(__always) public func mosaic(_ on: Bool) { on ? bgMosaicEnable(id) : bgMosaicDisable(id) }
}

public extension Background {
    /// Set the main-engine mosaic amount (`bgSetMosaic`).
    @inline(__always) static func setMosaic(dx: UInt32, dy: UInt32) { bgSetMosaic(dx, dy) }
    /// Set the sub-engine mosaic amount (`bgSetMosaicSub`).
    @inline(__always) static func setMosaicSub(dx: UInt32, dy: UInt32) { bgSetMosaicSub(dx, dy) }

    // MARK: Engine-wide VRAM pointers / bases (shim-backed macros)

    /// The main-engine background palette (`BG_PALETTE`).
    @inline(__always) static var palette: UnsafeMutablePointer<UInt16>? { nds_bg_palette() }
    /// The main-engine background graphics base (`BG_GFX`).
    @inline(__always) static var gfx: UnsafeMutablePointer<UInt16>? { nds_bg_gfx() }

    /// Address of character (tile) base block `n` (`CHAR_BASE_BLOCK`).
    @inline(__always) static func charBaseBlock(_ n: Int32) -> UnsafeMutableRawPointer? { nds_char_base_block(n) }
    /// Address of screen (map) base block `n` (`SCREEN_BASE_BLOCK`).
    @inline(__always) static func screenBaseBlock(_ n: Int32) -> UnsafeMutableRawPointer? { nds_screen_base_block(n) }

    /// Write a raw value to a `BGCTRL[layer]` register (`nds_set_bgctrl`).
    @inline(__always) static func setControl(layer: Int32, value: UInt32) { nds_set_bgctrl(layer, value) }
    /// A `BGCTRL` value for a 256-color 32x32 text background at the given bases.
    @inline(__always) static func control256(tileBase: Int32, mapBase: Int32) -> UInt32 {
        nds_bgctrl_value_256(tileBase, mapBase)
    }

    /// A `[bg][slot]` entry in VRAM bank E's extended BG palette (`VRAM_E_EXT_PALETTE`).
    @inline(__always) static func vramEExtPalette(bg: Int32, slot: Int32) -> UnsafeMutableRawPointer? { nds_vram_e_ext_palette(bg, slot) }
    /// A `[bg][slot]` entry in VRAM bank H's extended BG palette (`VRAM_H_EXT_PALETTE`).
    @inline(__always) static func vramHExtPalette(bg: Int32, slot: Int32) -> UnsafeMutableRawPointer? { nds_vram_h_ext_palette(bg, slot) }
}
