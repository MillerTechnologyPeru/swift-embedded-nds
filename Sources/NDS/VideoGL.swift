//===----------------------------------------------------------------------===//
// VideoGL.swift -- the 3D geometry engine ("GL").
//
// libnds exposes an OpenGL-flavored immediate-mode API. The float entry points
// (glRotatef, gluPerspective, ...) are real inline functions that import and
// call fine under Embedded Swift's soft-float, so we wrap them alongside the
// fixed-point (`*f32` / `*v16`) forms. `glBegin` / `glMatrixMode` take C enums,
// re-expressed here as Swift `Primitive` / `MatrixMode`.
//===----------------------------------------------------------------------===//

/// The 3D geometry engine.
public enum GL {

    /// Primitive assembly mode for `begin` (`GL_GLBEGIN_ENUM`).
    public enum Primitive {
        case triangles, quads, triangleStrip, quadStrip
        @inline(__always) var c: GL_GLBEGIN_ENUM {
            switch self {
            case .triangles:     return GL_TRIANGLES
            case .quads:         return GL_QUADS
            case .triangleStrip: return GL_TRIANGLE_STRIP
            case .quadStrip:     return GL_QUAD_STRIP
            }
        }
    }

    /// Which matrix the stack operations affect (`GL_MATRIX_MODE_ENUM`).
    public enum MatrixMode {
        case projection, position, modelview, texture
        @inline(__always) var c: GL_MATRIX_MODE_ENUM {
            switch self {
            case .projection: return GL_PROJECTION
            case .position:   return GL_POSITION
            case .modelview:  return GL_MODELVIEW
            case .texture:    return GL_TEXTURE
            }
        }
    }

    // MARK: Lifecycle

    @inline(__always) public static func initialize() { glInit() }
    /// Swap buffers / flush the geometry to the display (`glFlush`).
    @inline(__always) public static func flush(_ mode: UInt32 = 0) { glFlush(mode) }

    // MARK: Immediate-mode geometry

    @inline(__always) public static func begin(_ mode: Primitive) { glBegin(mode.c) }
    @inline(__always) public static func end() { glEnd() }

    /// Floating-point vertex (`glVertex3f`).
    @inline(__always) public static func vertex(_ x: Float, _ y: Float, _ z: Float) { glVertex3f(x, y, z) }
    /// Fixed-point vertex (`glVertex3v16`).
    @inline(__always) public static func vertex16(_ x: v16, _ y: v16, _ z: v16) { glVertex3v16(x, y, z) }

    @inline(__always) public static func color(_ c: Color) { glColor(c.rawValue) }
    @inline(__always) public static func color(r: UInt8, g: UInt8, b: UInt8) { glColor3b(r, g, b) }
    @inline(__always) public static func color(_ r: Float, _ g: Float, _ b: Float) { glColor3f(r, g, b) }

    /// Fixed-point normal, pre-packed with `NORMAL_PACK` (`glNormal`).
    @inline(__always) public static func normal(_ packed: UInt32) { glNormal(packed) }
    @inline(__always) public static func normal(_ x: Float, _ y: Float, _ z: Float) { glNormal3f(x, y, z) }

    /// Floating-point texture coordinate (`glTexCoord2f`).
    @inline(__always) public static func texCoord(_ s: Float, _ t: Float) { glTexCoord2f(s, t) }
    /// Fixed-point texture coordinate (`glTexCoord2t16`).
    @inline(__always) public static func texCoord16(_ u: t16, _ v: t16) { glTexCoord2t16(u, v) }
    @inline(__always) public static func texCoordf32(_ u: Int32, _ v: Int32) { glTexCoord2f32(u, v) }

    // MARK: Matrix stack

    @inline(__always) public static func matrixMode(_ mode: MatrixMode) { glMatrixMode(mode.c) }
    @inline(__always) public static func pushMatrix() { glPushMatrix() }
    @inline(__always) public static func popMatrix(_ count: Int32 = 1) { glPopMatrix(count) }
    @inline(__always) public static func loadIdentity() { glLoadIdentity() }
    @inline(__always) public static func resetMatrixStack() { glResetMatrixStack() }

    @inline(__always) public static func translatef32(_ x: Int32, _ y: Int32, _ z: Int32) { glTranslatef32(x, y, z) }
    @inline(__always) public static func translate(_ x: Float, _ y: Float, _ z: Float) { glTranslatef(x, y, z) }
    @inline(__always) public static func scalef32(_ x: Int32, _ y: Int32, _ z: Int32) { glScalef32(x, y, z) }
    @inline(__always) public static func scale(_ x: Float, _ y: Float, _ z: Float) { glScalef(x, y, z) }
    @inline(__always) public static func rotateXi(_ angle: Int32) { glRotateXi(angle) }
    @inline(__always) public static func rotateYi(_ angle: Int32) { glRotateYi(angle) }
    @inline(__always) public static func rotateZi(_ angle: Int32) { glRotateZi(angle) }
    @inline(__always) public static func rotatef32i(_ angle: Int32, _ x: Int32, _ y: Int32, _ z: Int32) { glRotatef32i(angle, x, y, z) }
    @inline(__always) public static func rotateX(_ angle: Float) { glRotateX(angle) }
    @inline(__always) public static func rotateY(_ angle: Float) { glRotateY(angle) }
    @inline(__always) public static func rotateZ(_ angle: Float) { glRotateZ(angle) }
    @inline(__always) public static func rotate(_ angle: Float, _ x: Float, _ y: Float, _ z: Float) { glRotatef(angle, x, y, z) }

    // MARK: Projection helpers

    @inline(__always) public static func perspective(fovy: Float, aspect: Float, near: Float, far: Float) {
        gluPerspective(fovy, aspect, near, far)
    }
    @inline(__always) public static func lookAt(eye: (Float, Float, Float), center: (Float, Float, Float), up: (Float, Float, Float)) {
        gluLookAt(eye.0, eye.1, eye.2, center.0, center.1, center.2, up.0, up.1, up.2)
    }
    @inline(__always) public static func ortho(_ left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ near: Float, _ far: Float) {
        glOrtho(left, right, bottom, top, near, far)
    }

    // MARK: Rendering state

    @inline(__always) public static func polyFmt(_ params: UInt32) { glPolyFmt(params) }
    @inline(__always) public static func enable(_ bits: Int32) { glEnable(bits) }
    @inline(__always) public static func disable(_ bits: Int32) { glDisable(bits) }
    @inline(__always) public static func material(_ mode: GL_MATERIALS_ENUM, _ color: Color) { glMaterialf(mode, color.rawValue) }
    /// Enable specular reflection with the material's shininess table (`glMaterialShinyness`).
    @inline(__always) public static func materialShininess() { glMaterialShinyness() }
    @inline(__always) public static func alphaFunc(threshold: Int32) { glAlphaFunc(threshold) }
    @inline(__always) public static func cutoffDepth(_ w: UInt16) { glCutoffDepth(w) }
    @inline(__always) public static func light(_ id: Int32, color: Color, x: v10, y: v10, z: v10) { glLight(id, color.rawValue, x, y, z) }
    @inline(__always) public static func viewport(_ x1: UInt8, _ y1: UInt8, _ x2: UInt8, _ y2: UInt8) { glViewport(x1, y1, x2, y2) }
    @inline(__always) public static func clearColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8) { glClearColor(r, g, b, a) }
    @inline(__always) public static func clearPolyID(_ id: UInt8) { glClearPolyID(id) }
    @inline(__always) public static func clearDepth(_ w: UInt16) { glClearDepth(w) }

    // MARK: Fog

    @inline(__always) public static func fogShift(_ shift: Int32) { glFogShift(shift) }
    @inline(__always) public static func fogOffset(_ offset: Int32) { glFogOffset(offset) }
    @inline(__always) public static func fogColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8) { glFogColor(r, g, b, a) }
    @inline(__always) public static func fogDensity(index: Int32, _ density: Int32) { glFogDensity(index, density) }

    // MARK: Display lists

    @inline(__always) public static func callList(_ list: UnsafePointer<UInt32>) { glCallList(list) }

    // MARK: Textures

    @inline(__always) public static func genTextures(_ n: Int32, _ names: UnsafeMutablePointer<Int32>) -> Int32 { glGenTextures(n, names) }
    @inline(__always) public static func deleteTextures(_ n: Int32, _ names: UnsafeMutablePointer<Int32>) -> Int32 { glDeleteTextures(n, names) }
    @inline(__always) public static func bindTexture(_ target: Int32, _ name: Int32) { glBindTexture(target, name) }
    @inline(__always) public static func resetTextures() { glResetTextures() }

    @discardableResult
    @inline(__always)
    public static func texImage2D(target: Int32, type: GL_TEXTURE_TYPE_ENUM, sizeX: Int32, sizeY: Int32,
                                  param: Int32, texture: UnsafeRawPointer) -> Int32 {
        glTexImage2D(target, 0, type, sizeX, sizeY, 0, param, texture)
    }
    @inline(__always) public static func texParameter(target: Int32, param: Int32) { glTexParameter(target, param) }

    /// Load a texture palette / colour table (`glColorTableEXT`).
    @inline(__always) public static func colorTable(_ table: UnsafePointer<UInt16>?, width: UInt16, target: Int32 = 0) {
        glColorTableEXT(target, 0, width, 0, 0, table)
    }
    /// Bind a previously-generated palette to the active texture (`glAssignColorTable`).
    @inline(__always) public static func assignColorTable(name: Int32, target: Int32 = 0) {
        glAssignColorTable(target, name)
    }

    // MARK: Geometry-engine state / matrices

    /// Read a geometry-engine integer (`glGetInt`), e.g. `GL_GET_VERTEX_RAM_COUNT`.
    @inline(__always) public static func getInt(_ param: GL_GET_ENUM, _ out: UnsafeMutablePointer<Int32>) { glGetInt(param, out) }
    /// Multiply the current matrix by a scale vector (`glScalev`).
    @inline(__always) public static func scale(vector v: UnsafePointer<GLvector>) { glScalev(v) }

    // MARK: Toon / outline

    @inline(__always) public static func setToonTable(_ table: UnsafePointer<UInt16>) { glSetToonTable(table) }
    @inline(__always) public static func setToonTableRange(start: Int32, end: Int32, color: Color) { glSetToonTableRange(start, end, color.rawValue) }
    @inline(__always) public static func setOutlineColor(id: Int32, color: Color) { glSetOutlineColor(id, color.rawValue) }

    // MARK: Geometry-engine status (via the shim register accessors)

    /// Whether the geometry engine is still busy (`GFX_BUSY`).
    @inline(__always) public static var isBusy: Bool { nds_gfx_busy() != 0 }
    /// Number of polygons currently in polygon RAM (`GFX_POLYGON_RAM_USAGE`).
    @inline(__always) public static var polygonRamUsage: UInt32 { nds_gfx_polygon_ram_usage() }
    /// Submit a pre-packed (`TEXTURE_PACK`) texcoord to `GFX_TEX_COORD`.
    @inline(__always) public static func submitPackedTexCoord(_ packed: UInt32) { nds_set_tex_coord(packed) }
}
