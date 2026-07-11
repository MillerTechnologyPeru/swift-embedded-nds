//---------------------------------------------------------------------------------
//
//  Swift port of the libnds bitmap_sprites example.
//
//  Three procedurally-filled sprites in different colour formats (direct bitmap,
//  256-colour, 16-colour), one of them rotating.
//
//---------------------------------------------------------------------------------

import NDS

struct MySprite {
	var gfx: UnsafeMutablePointer<UInt16>?
	let size: SpriteSize
	let format: OAM.ColorFormat
	let rotationIndex: Int32
	let paletteAlpha: Int32
	let x: Int32
	let y: Int32
}

var sprites = [
	MySprite(gfx: nil, size: SpriteSize_32x32, format: .bmp,      rotationIndex: 0, paletteAlpha: 15, x: 20, y: 15),
	MySprite(gfx: nil, size: SpriteSize_32x32, format: .color256, rotationIndex: 0, paletteAlpha: 0,  x: 20, y: 80),
	MySprite(gfx: nil, size: SpriteSize_32x32, format: .color16,  rotationIndex: 0, paletteAlpha: 1,  x: 20, y: 136),
]

Video.setModeSub(.mode0_2D)
Console.demoInit()

let sub = OAM.sub
sub.initialize(mapping: SpriteMapping_Bmp_1D_128)
Video.setBankD(VRAM_D_SUB_SPRITE)

for i in 0 ..< 3 {
	sprites[i].gfx = sub.allocateGfx(size: sprites[i].size, format: sprites[i].format)
}

Console.print("\u{1b}[1;1HDirect Bitmap:")
Console.print("\u{1b}[9;1H256 color:")
Console.print("\u{1b}[16;1H16 color:")

// fill the bitmap sprite with red
DMA.fillHalfWords(Color(a: true, r: 31, g: 0, b: 0).rawValue, to: sprites[0].gfx!, size: 32 * 32 * 2)
// 256-colour sprite filled with palette index 1 (2 pixels per halfword)
DMA.fillHalfWords((1 << 8) | 1, to: sprites[1].gfx!, size: 32 * 32)
// 16-colour sprite filled with index 1 (4 pixels per halfword)
DMA.fillHalfWords((1 << 12) | (1 << 8) | (1 << 4) | 1, to: sprites[2].gfx!, size: 32 * 32 / 2)

let palSub = OAM.subPalette!
palSub[1] = Color(r: 0, g: 31, b: 0).rawValue        // 256-colour sprite -> blue/green
palSub[16 + 1] = Color(r: 0, g: 0, b: 31).rawValue   // 16-colour sprite

var angle: Int32 = 0

while System.mainLoop {
	for i in 0 ..< 3 {
		sub.set(id: Int32(i), x: sprites[i].x, y: sprites[i].y, priority: 0,
		        paletteAlpha: sprites[i].paletteAlpha, size: sprites[i].size, format: sprites[i].format,
		        gfx: sprites[i].gfx, affineIndex: sprites[i].rotationIndex, sizeDouble: true)
	}

	sub.rotateScale(rotId: 0, angle: angle, sx: 1 << 8, sy: 1 << 8)
	angle += 64

	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }

	sub.update()
}
