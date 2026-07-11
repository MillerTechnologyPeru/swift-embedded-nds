//===----------------------------------------------------------------------===//
// PosTest.swift -- hardware position test (3D picking).
//
// Transforms a point by the current matrices and reports its resulting screen-
// space W/X/Y/Z, used for picking objects under the stylus.
//===----------------------------------------------------------------------===//

public enum PosTest {
    /// Run a synchronous position test on the given point (`PosTest`).
    @inline(__always) public static func test(x: v16, y: v16, z: v16) { CNDS.PosTest(x, y, z) }
    /// Start an asynchronous position test (`PosTest_Asynch`).
    @inline(__always) public static func testAsync(x: v16, y: v16, z: v16) { PosTest_Asynch(x, y, z) }
    /// Whether a position test is still running (`PosTestBusy`).
    @inline(__always) public static var isBusy: Bool { PosTestBusy() }

    @inline(__always) public static var w: Int32 { PosTestWresult() }
    @inline(__always) public static var x: Int32 { PosTestXresult() }
    @inline(__always) public static var y: Int32 { PosTestYresult() }
    @inline(__always) public static var z: Int32 { PosTestZresult() }
}
