//===----------------------------------------------------------------------===//
// BoxTest.swift -- hardware view-frustum box test (visibility culling).
//
// Returns whether an axis-aligned box intersects the view frustum, so you can
// skip drawing off-screen geometry.
//===----------------------------------------------------------------------===//

public enum BoxTest {
    /// Fixed-point box test; returns true if visible (`BoxTest`).
    @inline(__always)
    public static func test(x: v16, y: v16, z: v16, width: v16, height: v16, depth: v16) -> Bool {
        CNDS.BoxTest(x, y, z, width, height, depth) != 0
    }

    /// Floating-point box test (`BoxTestf`).
    @inline(__always)
    public static func test(x: Float, y: Float, z: Float, width: Float, height: Float, depth: Float) -> Bool {
        BoxTestf(x, y, z, width, height, depth) != 0
    }

    /// Start an asynchronous box test; read `result` after the GE finishes.
    @inline(__always)
    public static func testAsync(x: v16, y: v16, z: v16, width: v16, height: v16, depth: v16) {
        BoxTest_Asynch(x, y, z, height, width, depth)
    }

    /// The result of the last asynchronous box test (`BoxTestResult`).
    @inline(__always) public static var result: Bool { BoxTestResult() != 0 }
}
