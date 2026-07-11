//===----------------------------------------------------------------------===//
// Decompress.swift -- BIOS-backed decompression (LZ77 / Huffman / RLE).
//
// Used to expand grit-compressed assets into VRAM or main RAM.
//===----------------------------------------------------------------------===//

public enum Decompress {
    /// A supported decompression scheme (`DecompressType`).
    public enum Kind {
        case lz77, lz77Vram, huffman, rle, rleVram
        @inline(__always) var c: DecompressType {
            switch self {
            case .lz77:     return LZ77
            case .lz77Vram: return LZ77Vram
            case .huffman:  return HUFF
            case .rle:      return RLE
            case .rleVram:  return RLEVram
            }
        }
    }

    /// Decompress `data` into `dst` using the given scheme (`decompress`).
    @inline(__always)
    public static func run(_ data: UnsafeRawPointer, into dst: UnsafeMutableRawPointer, kind: Kind) {
        decompress(data, dst, kind.c)
    }
}
