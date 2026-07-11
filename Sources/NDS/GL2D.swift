//===----------------------------------------------------------------------===//
// GL2D.swift -- Easy GL2D, the 2D-over-3D helper that ships with libnds.
//
// Draws sprites and primitives on the 3D engine with a simple 2D coordinate
// system. Colors are packed 15-bit BGR `Int32` values (matching Easy GL2D's
// `int color` API — build them with `Color(...).rawValue` or `RGB15`);
// `flipmode` uses the `GL_FLIP_*` bits (re-exported from CNDS).
//===----------------------------------------------------------------------===//

public enum GL2D {
    /// Set up the 3D engine for 2D drawing (`glScreen2D`).
    @inline(__always) public static func screen2D() { glScreen2D() }
    /// Begin a 2D drawing batch (`glBegin2D`).
    @inline(__always) public static func begin2D() { glBegin2D() }
    /// End a 2D drawing batch (`glEnd2D`).
    @inline(__always) public static func end2D() { glEnd2D() }

    /// Bind the texture a following `sprite`/`spriteRotate` draws from
    /// (`glSetActiveTexture`) — used with the palette-swap color tables.
    @inline(__always) public static func setActiveTexture(_ id: Int32) { glSetActiveTexture(id) }

    // MARK: Primitives (color is a packed 15-bit BGR value)

    @inline(__always) public static func putPixel(x: Int32, y: Int32, color: Int32) { glPutPixel(x, y, color) }
    @inline(__always) public static func line(x1: Int32, y1: Int32, x2: Int32, y2: Int32, color: Int32) {
        glLine(x1, y1, x2, y2, color)
    }
    @inline(__always) public static func box(x1: Int32, y1: Int32, x2: Int32, y2: Int32, color: Int32) {
        glBox(x1, y1, x2, y2, color)
    }
    @inline(__always) public static func boxFilled(x1: Int32, y1: Int32, x2: Int32, y2: Int32, color: Int32) {
        glBoxFilled(x1, y1, x2, y2, color)
    }
    @inline(__always) public static func boxFilledGradient(x1: Int32, y1: Int32, x2: Int32, y2: Int32,
                                                           color1: Int32, color2: Int32, color3: Int32, color4: Int32) {
        glBoxFilledGradient(x1, y1, x2, y2, color1, color2, color3, color4)
    }
    @inline(__always) public static func triangle(x1: Int32, y1: Int32, x2: Int32, y2: Int32, x3: Int32, y3: Int32, color: Int32) {
        glTriangle(x1, y1, x2, y2, x3, y3, color)
    }
    @inline(__always) public static func triangleFilled(x1: Int32, y1: Int32, x2: Int32, y2: Int32, x3: Int32, y3: Int32, color: Int32) {
        glTriangleFilled(x1, y1, x2, y2, x3, y3, color)
    }
    @inline(__always) public static func triangleFilledGradient(x1: Int32, y1: Int32, x2: Int32, y2: Int32, x3: Int32, y3: Int32,
                                                               color1: Int32, color2: Int32, color3: Int32) {
        glTriangleFilledGradient(x1, y1, x2, y2, x3, y3, color1, color2, color3)
    }

    // MARK: Sprites (flipmode is a GL_FLIP_* bitmask)

    @inline(__always) public static func sprite(x: Int32, y: Int32, flip: Int32 = 0, _ image: UnsafePointer<glImage>) {
        glSprite(x, y, flip, image)
    }
    @inline(__always) public static func spriteScale(x: Int32, y: Int32, scale: Int32, flip: Int32 = 0, _ image: UnsafePointer<glImage>) {
        glSpriteScale(x, y, scale, flip, image)
    }
    @inline(__always) public static func spriteScaleXY(x: Int32, y: Int32, scaleX: Int32, scaleY: Int32, flip: Int32 = 0, _ image: UnsafePointer<glImage>) {
        glSpriteScaleXY(x, y, scaleX, scaleY, flip, image)
    }
    @inline(__always) public static func spriteRotate(x: Int32, y: Int32, angle: Int32, flip: Int32 = 0, _ image: UnsafePointer<glImage>) {
        glSpriteRotate(x, y, angle, flip, image)
    }
    @inline(__always) public static func spriteRotateScale(x: Int32, y: Int32, angle: Int32, scale: Int32, flip: Int32 = 0, _ image: UnsafePointer<glImage>) {
        glSpriteRotateScale(x, y, angle, scale, flip, image)
    }
    @inline(__always) public static func spriteRotateScaleXY(x: Int32, y: Int32, angle: Int32, scaleX: Int32, scaleY: Int32, flip: Int32 = 0, _ image: UnsafePointer<glImage>) {
        glSpriteRotateScaleXY(x, y, angle, scaleX, scaleY, flip, image)
    }
    @inline(__always) public static func spriteStretchHorizontal(x: Int32, y: Int32, lengthX: Int32, _ image: UnsafePointer<glImage>) {
        glSpriteStretchHorizontal(x, y, lengthX, image)
    }

    // MARK: Loading texture atlases

    @discardableResult
    @inline(__always)
    public static func loadSpriteSet(_ sprite: UnsafeMutablePointer<glImage>, frames: UInt32,
                                     texcoords: UnsafePointer<UInt32>, type: GL_TEXTURE_TYPE_ENUM,
                                     sizeX: Int32, sizeY: Int32, param: Int32, paletteWidth: Int32,
                                     palette: UnsafePointer<UInt16>?, texture: UnsafePointer<UInt8>) -> Int32 {
        glLoadSpriteSet(sprite, frames, texcoords, type, sizeX, sizeY, param, paletteWidth, palette, texture)
    }

    @discardableResult
    @inline(__always)
    public static func loadTileSet(_ sprite: UnsafeMutablePointer<glImage>, tileWidth: Int32, tileHeight: Int32,
                                   bmpWidth: Int32, bmpHeight: Int32, type: GL_TEXTURE_TYPE_ENUM,
                                   sizeX: Int32, sizeY: Int32, param: Int32, paletteWidth: Int32,
                                   palette: UnsafePointer<UInt16>?, texture: UnsafePointer<UInt8>) -> Int32 {
        glLoadTileSet(sprite, tileWidth, tileHeight, bmpWidth, bmpHeight, type, sizeX, sizeY, param, paletteWidth, palette, texture)
    }
}
