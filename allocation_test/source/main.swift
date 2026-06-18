//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Sprites/allocation_test example.
//
//  A stress test of the libnds sprite-graphics allocator: 128 sprites of random
//  sizes continually allocate/free OAM gfx as they bounce off-screen, with live
//  memory-usage stats.
//
//---------------------------------------------------------------------------------

import CNDS

let SPRITE_MAX = 128
let spriteMemSize: UInt32 = 128 * 1024
let oam = nds_oam_main()!.assumingMemoryBound(to: OamState.self)

// the available hardware sprite sizes, for random selection
let sizes: [SpriteSize] = [
	SpriteSize_8x8, SpriteSize_8x16, SpriteSize_16x8, SpriteSize_8x32,
	SpriteSize_16x16, SpriteSize_32x8, SpriteSize_16x32, SpriteSize_32x16,
	SpriteSize_32x32, SpriteSize_32x64, SpriteSize_64x32, SpriteSize_64x64,
]

// our game entity -- richer than a raw OAM entry
struct MySprite {
	var x: Int32 = 0, y: Int32 = 0, z: Int32 = 0
	var dx: Int32 = 0, dy: Int32 = 0
	var alive = false
	var gfx: UnsafeMutablePointer<UInt16>? = nil
	var format: SpriteColorFormat = SpriteColorFormat_256Color
	var size: SpriteSize = SpriteSize_8x8
}

var sprites = [MySprite](repeating: MySprite(), count: SPRITE_MAX)
var spriteMemoryUsage: UInt32 = 0
var oomCount: UInt32 = 0
var allocationCount: UInt32 = 0
var oom = false

@inline(__always) func sizeBytes(_ s: SpriteSize) -> UInt32 { (UInt32(s.rawValue) & 0xFFF) << 5 }

func createSprite(_ s: inout MySprite, x: Int32, y: Int32, size: SpriteSize, dx: Int32, dy: Int32) {
	s.alive = true
	s.x = x; s.y = y; s.z = 0
	s.dx = dx; s.dy = dy
	s.size = size
	s.format = SpriteColorFormat_256Color
	s.gfx = oamAllocateGfx(oam, size, s.format)
	allocationCount += 1
	if s.gfx != nil {
		spriteMemoryUsage += sizeBytes(size)
		oom = false
	} else {
		oom = true
		if spriteMemoryUsage + sizeBytes(size) < spriteMemSize { oomCount += 1 }
	}
}

func killSprite(_ s: inout MySprite) {
	s.alive = false
	if let gfx = s.gfx {
		oamFreeGfx(oam, gfx)
		spriteMemoryUsage -= sizeBytes(s.size)
	}
	s.gfx = nil
}

func randomSprite(_ s: inout MySprite) {
	let c = UInt16(rand() % 256)
	let color = c | (c << 8)   // two pixels at a time
	let size = sizes[Int(rand() % 12)]
	createSprite(&s, x: rand() % 256, y: rand() % 192, size: size, dx: rand() % 4 - 2, dy: rand() % 4 - 2)
	if s.dx == 0 && s.dy == 0 { s.dx = rand() % 3 + 1; s.dy = rand() % 3 + 1 }

	// reload gfx each time -- this is as much a test of the allocator as of the API
	if let gfx = s.gfx {
		let count = Int((UInt32(size.rawValue) & 0xFFF) << 4)   // 16-bit words
		for i in 0 ..< count { gfx[i] = color }
	} else {
		s.alive = false
	}
}

func moveSprites() {
	for i in 0 ..< SPRITE_MAX {
		sprites[i].x += sprites[i].dx
		sprites[i].y += sprites[i].dy
		if sprites[i].x >= 256 || sprites[i].x < 0 || sprites[i].y >= 192 || sprites[i].y < 0 {
			killSprite(&sprites[i])
			randomSprite(&sprites[i])
		}
	}
}

func updateSprites() {
	// dead sprites sort ahead of living ones; living ones sort by depth
	sprites.sort { a, b in
		if a.alive != b.alive { return !a.alive }
		return a.z < b.z
	}
	for i in 0 ..< SPRITE_MAX {
		oamSet(oam, Int32(i), sprites[i].x, sprites[i].y, 0, 0,
		       sprites[i].size, sprites[i].format, sprites[i].gfx,
		       -1, false, !sprites[i].alive, false, false, false)
	}
}

videoSetMode(MODE_0_2D.rawValue)
videoSetModeSub(MODE_0_2D.rawValue)
vramSetBankA(VRAM_A_MAIN_SPRITE)
vramSetBankB(VRAM_B_MAIN_SPRITE)
vramSetBankD(VRAM_D_SUB_SPRITE)

consoleDemoInit()
oamInit(oam, SpriteMapping_1D_128, false)

for i in 0 ..< SPRITE_MAX { randomSprite(&sprites[i]) }

let mainPal = nds_sprite_palette()!
let subPal = nds_sprite_palette_sub()!
for i in 0 ..< 256 {
	mainPal[i] = UInt16(truncatingIfNeeded: rand())
	subPal[i] = UInt16(truncatingIfNeeded: rand())
}

var memUsageTemp: UInt32 = 0xFFFFFFFF

while pmMainLoop() {
	moveSprites()
	updateSprites()

	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }

	oamUpdate(oam)

	if oom { memUsageTemp = min(memUsageTemp, spriteMemoryUsage) }

	consoleClear()
	nds_printf_2i("Memory usage: %lu %lu%% \n",
	              Int32(bitPattern: spriteMemoryUsage),
	              Int32(bitPattern: 100 * spriteMemoryUsage / spriteMemSize))
	nds_printf_1i("Percentage fail: %lu%% \n",
	              Int32(bitPattern: allocationCount == 0 ? 0 : oomCount * 100 / allocationCount))
	nds_printf_2i("Lowest usage at fail %lu %lu%% \n",
	              Int32(bitPattern: memUsageTemp),
	              Int32(bitPattern: 100 * memUsageTemp / spriteMemSize))
}
