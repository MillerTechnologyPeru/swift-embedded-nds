// swift-tools-version:5.9
import PackageDescription

// swift-embedded-nds -- an idiomatic Swift overlay over libnds for the Nintendo DS.
//
// NOTE: This package is a *source library*. SwiftPM cannot cross-compile Embedded
// Swift to the DS's bare-metal armv5te target, so `swift build` does not produce a
// runnable `.nds`. The manifest exists for structure, editor/IDE support, and a
// single source of truth for the C interop; the actual ROMs are built by the
// per-example Makefiles (see common/common.mk), which compile the `NDS` target as
// a standalone Embedded Swift module and link it into each example.
let package = Package(
    name: "NDS",
    products: [
        .library(name: "NDS", targets: ["NDS"]),
    ],
    targets: [
        // The C interop: libnds (<nds.h>) + gl2d + dswifi + our shim, exposed as
        // `import CNDS`. shim.c lives in this folder but is compiled by common.mk,
        // not SwiftPM -- systemLibrary targets do not build sources.
        .systemLibrary(name: "CNDS", path: "Sources/CNDS"),

        // The idiomatic Swift overlay. Depends on (and @_exported re-exports) CNDS.
        .target(name: "NDS", dependencies: ["CNDS"]),
    ]
)
