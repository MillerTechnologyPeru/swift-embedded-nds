//===----------------------------------------------------------------------===//
// Exports.swift -- re-export the raw C layer.
//
// `import NDS` gives an example both the idiomatic wrappers in this module and
// the full underlying libnds API. Anything not yet wrapped here (or raw grit
// asset symbols injected via a bridging header) stays reachable as before, so
// adopting NDS never regresses an example.
//===----------------------------------------------------------------------===//

@_exported import CNDS
