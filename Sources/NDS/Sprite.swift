//===----------------------------------------------------------------------===//
// Sprite.swift -- OAM (object / sprite) management.
//
// libnds routes every sprite call through an `OamState` for the main or sub
// engine (the `oamMain` / `oamSub` globals). Taking the address of a C global
// imports awkwardly into Swift, so the shim hands back stable pointers via
// `nds_oam_main()` / `nds_oam_sub()`. We wrap those as an `OAM` value with
// methods. `SpriteSize` / `SpriteMapping` have many cases and pass through as
// the imported C enums; the 3-case color format gets a Swift enum.
//===----------------------------------------------------------------------===//

/// The object attribute memory for one engine. Use `OAM.main` / `OAM.sub`.
public struct OAM {
    /// Pointer to the underlying `OamState`.
    public let state: UnsafeMutablePointer<OamState>

    @inline(__always) public init(_ state: UnsafeMutablePointer<OamState>) { self.state = state }

    /// The main-engine OAM (`oamMain`).
    @inline(__always) public static var main: OAM {
        OAM(nds_oam_main().assumingMemoryBound(to: OamState.self))
    }
    /// The sub-engine OAM (`oamSub`).
    @inline(__always) public static var sub: OAM {
        OAM(nds_oam_sub().assumingMemoryBound(to: OamState.self))
    }

    /// Sprite pixel color format (`SpriteColorFormat`).
    public enum ColorFormat {
        case color16, color256, bmp
        @inline(__always) var c: SpriteColorFormat {
            switch self {
            case .color16:  return SpriteColorFormat_16Color
            case .color256: return SpriteColorFormat_256Color
            case .bmp:      return SpriteColorFormat_Bmp
            }
        }
    }

    // MARK: Lifecycle

    @inline(__always) public func initialize(mapping: SpriteMapping, extPalette: Bool = false) {
        oamInit(state, mapping, extPalette)
    }
    @inline(__always) public func enable()  { oamEnable(state) }
    @inline(__always) public func disable() { oamDisable(state) }
    /// Commit OAM shadow memory to hardware; call once per frame (`oamUpdate`).
    @inline(__always) public func update() { oamUpdate(state) }

    // MARK: Gfx allocation

    @inline(__always) public func allocateGfx(size: SpriteSize, format: ColorFormat) -> UnsafeMutablePointer<UInt16>? {
        oamAllocateGfx(state, size, format.c)
    }
    @inline(__always) public func freeGfx(_ gfx: UnsafeRawPointer?) { oamFreeGfx(state, gfx) }
    @inline(__always) public func gfxPointer(index: Int32) -> UnsafeMutablePointer<UInt16>? { oamGetGfxPtr(state, index) }
    @inline(__always) public var fragmentCount: Int32 { oamCountFragments(state) }
    @inline(__always) public func resetAllocator() { oamAllocReset(state) }

    // MARK: Setting sprites

    /// The full `oamSet`. Most call sites want the smaller helpers below.
    @inline(__always)
    public func set(id: Int32, x: Int32, y: Int32, priority: Int32, paletteAlpha: Int32,
                    size: SpriteSize, format: ColorFormat, gfx: UnsafeRawPointer?,
                    affineIndex: Int32 = -1, sizeDouble: Bool = false, hide: Bool = false,
                    hflip: Bool = false, vflip: Bool = false, mosaic: Bool = false) {
        oamSet(state, id, x, y, priority, paletteAlpha, size, format.c, gfx,
               affineIndex, sizeDouble, hide, hflip, vflip, mosaic)
    }

    @inline(__always) public func setXY(id: Int32, x: Int32, y: Int32) { oamSetXY(state, id, x, y) }
    @inline(__always) public func setPriority(id: Int32, _ priority: Int32) { oamSetPriority(state, id, priority) }
    @inline(__always) public func setPalette(id: Int32, _ palette: Int32) { oamSetPalette(state, id, palette) }
    @inline(__always) public func setAlpha(id: Int32, _ alpha: Int32) { oamSetAlpha(state, id, alpha) }
    @inline(__always) public func setGfx(id: Int32, size: SpriteSize, format: ColorFormat, gfx: UnsafeRawPointer?) {
        oamSetGfx(state, id, size, format.c, gfx)
    }
    @inline(__always) public func setAffineIndex(id: Int32, _ affineIndex: Int32, sizeDouble: Bool) {
        oamSetAffineIndex(state, id, affineIndex, sizeDouble)
    }
    @inline(__always) public func setHidden(id: Int32, _ hide: Bool) { oamSetHidden(state, id, hide) }
    @inline(__always) public func setFlip(id: Int32, hflip: Bool, vflip: Bool) { oamSetFlip(state, id, hflip, vflip) }
    @inline(__always) public func setMosaic(id: Int32, _ mosaic: Bool) { oamSetMosaicEnabled(state, id, mosaic) }

    // MARK: Clearing / affine

    @inline(__always) public func clear(start: Int32 = 0, count: Int32 = 128) { oamClear(state, start, count) }
    @inline(__always) public func clearSprite(id: Int32) { oamClearSprite(state, id) }
    @inline(__always) public func rotateScale(rotId: Int32, angle: Int32, sx: Int32, sy: Int32) {
        oamRotateScale(state, rotId, angle, sx, sy)
    }
    @inline(__always) public func affineTransformation(rotId: Int32, hdx: Int32, hdy: Int32, vdx: Int32, vdy: Int32) {
        oamAffineTransformation(state, rotId, hdx, hdy, vdx, vdy)
    }

    // MARK: Palettes / gfx VRAM (via the shim pointer macros)

    /// The main sprite palette (`SPRITE_PALETTE`).
    @inline(__always) public static var mainPalette: UnsafeMutablePointer<UInt16>? { nds_sprite_palette() }
    /// The sub sprite palette (`SPRITE_PALETTE_SUB`).
    @inline(__always) public static var subPalette: UnsafeMutablePointer<UInt16>? { nds_sprite_palette_sub() }
    /// The main sprite graphics VRAM (`SPRITE_GFX`).
    @inline(__always) public static var mainGfx: UnsafeMutablePointer<UInt16>? { nds_sprite_gfx() }
    /// The sub sprite graphics VRAM (`SPRITE_GFX_SUB`).
    @inline(__always) public static var subGfx: UnsafeMutablePointer<UInt16>? { nds_sprite_gfx_sub() }

    /// Write one entry of VRAM bank F's extended sprite palette
    /// (`VRAM_F_EXT_SPR_PALETTE`).
    @inline(__always) public static func setExtPaletteF(palette: Int32, index: Int32, color: Color) {
        nds_set_ext_spr_palette_f(palette, index, color.rawValue)
    }

    /// Initialize a 4x3 grid of 64x64 bitmap sprites on the sub OAM (the
    /// dual-screen capture demo's helper, `nds_init_sub_sprites_grid`).
    @inline(__always) public static func initSubSpritesGrid() { nds_init_sub_sprites_grid() }
}
