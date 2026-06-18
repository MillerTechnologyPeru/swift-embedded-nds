//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Sprites/animate_simple example (dovoto).
//
//  Two sprite-animation strategies: the "man" copies the current 32x32 frame into
//  one gfx slot each time it changes (saves VRAM); the "woman" pre-loads all 12
//  frames into VRAM and just switches which pointer she draws (faster).
//
//---------------------------------------------------------------------------------

import CNDS

let FRAMES_PER_ANIMATION: Int32 = 3
let W_UP: Int32 = 0, W_RIGHT: Int32 = 1, W_DOWN: Int32 = 2, W_LEFT: Int32 = 3

struct Man {
	var x: Int32 = 0, y: Int32 = 0
	var spriteGfxMem: UnsafeMutablePointer<UInt16>? = nil
	var frameGfx: UnsafePointer<UInt8>? = nil
	var state: Int32 = 0
	var animFrame: Int32 = 0
}

struct Woman {
	var x: Int32 = 0, y: Int32 = 0
	var spriteGfxMem = [UnsafeMutablePointer<UInt16>?](repeating: nil, count: 12)
	var gfxFrame = 0
	var state: Int32 = 0
	var animFrame: Int32 = 0
}

func initMan(_ s: inout Man, _ gfx: UnsafePointer<UInt8>) {
	s.spriteGfxMem = oamAllocateGfx(&oamMain, SpriteSize_32x32, SpriteColorFormat_256Color)
	s.frameGfx = gfx
}

func animateMan(_ s: inout Man) {
	let frame = s.animFrame + s.state * FRAMES_PER_ANIMATION
	let offset = s.frameGfx! + Int(frame) * 32 * 32
	dmaCopy(offset, s.spriteGfxMem, 32 * 32)
}

func initWoman(_ s: inout Woman, _ gfx: UnsafePointer<UInt8>) {
	var p = gfx
	for i in 0 ..< 12 {
		s.spriteGfxMem[i] = oamAllocateGfx(&oamSub, SpriteSize_32x32, SpriteColorFormat_256Color)
		dmaCopy(p, s.spriteGfxMem[i], 32 * 32)
		p += 32 * 32
	}
}

func animateWoman(_ s: inout Woman) {
	s.gfxFrame = Int(s.animFrame + s.state * FRAMES_PER_ANIMATION)
}

var man = Man()
var woman = Woman()

videoSetMode(MODE_0_2D.rawValue)
videoSetModeSub(MODE_0_2D.rawValue)
vramSetBankA(VRAM_A_MAIN_SPRITE)
vramSetBankD(VRAM_D_SUB_SPRITE)
oamInit(&oamMain, SpriteMapping_1D_128, false)
oamInit(&oamSub, SpriteMapping_1D_128, false)

initMan(&man, nds_asset_manTiles()!.assumingMemoryBound(to: UInt8.self))
initWoman(&woman, nds_asset_womanTiles()!.assumingMemoryBound(to: UInt8.self))
dmaCopy(nds_asset_manPal(), nds_sprite_palette(), 512)
dmaCopy(nds_asset_womanPal(), nds_sprite_palette_sub(), 512)

while pmMainLoop() {
	scanKeys()
	let keys = keysHeld()
	if keys & KEY_START != 0 { break }

	if keys != 0 {
		if keys & KEY_UP != 0 {
			if man.y >= 0 { man.y -= 1 }
			if woman.y >= 0 { woman.y -= 1 }
			man.state = W_UP; woman.state = W_UP
		}
		if keys & KEY_LEFT != 0 {
			if man.x >= 0 { man.x -= 1 }
			if woman.x >= 0 { woman.x -= 1 }
			man.state = W_LEFT; woman.state = W_LEFT
		}
		if keys & KEY_RIGHT != 0 {
			if man.x <= 256 { man.x += 1 }
			if woman.x <= 256 { woman.x += 1 }
			man.state = W_RIGHT; woman.state = W_RIGHT
		}
		if keys & KEY_DOWN != 0 {
			if man.y <= 192 { man.y += 1 }
			if woman.y <= 192 { woman.y += 1 }
			man.state = W_DOWN; woman.state = W_DOWN
		}
		man.animFrame += 1
		woman.animFrame += 1
		if man.animFrame >= FRAMES_PER_ANIMATION { man.animFrame = 0 }
		if woman.animFrame >= FRAMES_PER_ANIMATION { woman.animFrame = 0 }
	}

	animateMan(&man)
	animateWoman(&woman)

	oamSet(&oamMain, 0, man.x, man.y, 0, 0, SpriteSize_32x32, SpriteColorFormat_256Color,
	       man.spriteGfxMem, -1, false, false, false, false, false)
	oamSet(&oamSub, 0, woman.x, woman.y, 0, 0, SpriteSize_32x32, SpriteColorFormat_256Color,
	       woman.spriteGfxMem[woman.gfxFrame], -1, false, false, false, false, false)

	threadWaitForVBlank()
	oamUpdate(&oamMain)
	oamUpdate(&oamSub)
}
