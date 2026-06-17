//---------------------------------------------------------------------------------
//
//  Swift port of the libnds bitmap_sprites example.
//
//  Three procedurally-filled sprites in different colour formats (direct bitmap,
//  256-colour, 16-colour), one of them rotating.
//
//---------------------------------------------------------------------------------

import CNDS

@inline(__always) func rgb15(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	r | (g << 5) | (b << 10)
}
@inline(__always) func argb16(_ a: UInt16, _ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 {
	(a << 15) | r | (g << 5) | (b << 10)
}

struct MySprite {
	var gfx: UnsafeMutablePointer<UInt16>?
	let size: SpriteSize
	let format: SpriteColorFormat
	let rotationIndex: Int32
	let paletteAlpha: Int32
	let x: Int32
	let y: Int32
}

var sprites = [
	MySprite(gfx: nil, size: SpriteSize_32x32, format: SpriteColorFormat_Bmp,      rotationIndex: 0, paletteAlpha: 15, x: 20, y: 15),
	MySprite(gfx: nil, size: SpriteSize_32x32, format: SpriteColorFormat_256Color, rotationIndex: 0, paletteAlpha: 0,  x: 20, y: 80),
	MySprite(gfx: nil, size: SpriteSize_32x32, format: SpriteColorFormat_16Color,  rotationIndex: 0, paletteAlpha: 1,  x: 20, y: 136),
]

videoSetModeSub(MODE_0_2D.rawValue)
consoleDemoInit()

oamInit(&oamSub, SpriteMapping_Bmp_1D_128, false)
vramSetBankD(VRAM_D_SUB_SPRITE)

for i in 0 ..< 3 {
	sprites[i].gfx = oamAllocateGfx(&oamSub, sprites[i].size, sprites[i].format)
}

nds_puts("\u{1b}[1;1HDirect Bitmap:")
nds_puts("\u{1b}[9;1H256 color:")
nds_puts("\u{1b}[16;1H16 color:")

// fill the bitmap sprite with red
dmaFillHalfWords(argb16(1, 31, 0, 0), sprites[0].gfx, 32 * 32 * 2)
// 256-colour sprite filled with palette index 1 (2 pixels per halfword)
dmaFillHalfWords((1 << 8) | 1, sprites[1].gfx, 32 * 32)
// 16-colour sprite filled with index 1 (4 pixels per halfword)
dmaFillHalfWords((1 << 12) | (1 << 8) | (1 << 4) | 1, sprites[2].gfx, 32 * 32 / 2)

let palSub = nds_sprite_palette_sub()!
palSub[1] = rgb15(0, 31, 0)        // 256-colour sprite -> blue/green
palSub[16 + 1] = rgb15(0, 0, 31)   // 16-colour sprite

var angle: Int32 = 0

while pmMainLoop() {
	for i in 0 ..< 3 {
		oamSet(&oamSub, Int32(i), sprites[i].x, sprites[i].y, 0,
		       sprites[i].paletteAlpha, sprites[i].size, sprites[i].format,
		       sprites[i].gfx, sprites[i].rotationIndex,
		       true, false, false, false, false)
	}

	oamRotateScale(&oamSub, 0, angle, 1 << 8, 1 << 8)
	angle += 64

	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	oamUpdate(&oamSub)
}
