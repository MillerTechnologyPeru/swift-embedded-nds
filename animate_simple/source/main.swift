//---------------------------------------------------------------------------------
//
//  Swift port of the libnds Sprites/animate_simple example (dovoto).
//
//  Two sprite-animation strategies: the "man" copies the current 32x32 frame into
//  one gfx slot each time it changes (saves VRAM); the "woman" pre-loads all 12
//  frames into VRAM and just switches which pointer she draws (faster).
//
//---------------------------------------------------------------------------------

import NDS

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
	s.spriteGfxMem = OAM.main.allocateGfx(size: SpriteSize_32x32, format: .color256)
	s.frameGfx = gfx
}

func animateMan(_ s: inout Man) {
	let frame = s.animFrame + s.state * FRAMES_PER_ANIMATION
	let offset = s.frameGfx! + Int(frame) * 32 * 32
	DMA.copy(from: offset, to: s.spriteGfxMem!, size: 32 * 32)
}

func initWoman(_ s: inout Woman, _ gfx: UnsafePointer<UInt8>) {
	var p = gfx
	for i in 0 ..< 12 {
		s.spriteGfxMem[i] = OAM.sub.allocateGfx(size: SpriteSize_32x32, format: .color256)
		DMA.copy(from: p, to: s.spriteGfxMem[i]!, size: 32 * 32)
		p += 32 * 32
	}
}

func animateWoman(_ s: inout Woman) {
	s.gfxFrame = Int(s.animFrame + s.state * FRAMES_PER_ANIMATION)
}

var man = Man()
var woman = Woman()

Video.setMode(.mode0_2D)
Video.setModeSub(.mode0_2D)
Video.setBankA(VRAM_A_MAIN_SPRITE)
Video.setBankD(VRAM_D_SUB_SPRITE)
OAM.main.initialize(mapping: SpriteMapping_1D_128)
OAM.sub.initialize(mapping: SpriteMapping_1D_128)

initMan(&man, nds_asset_manTiles()!.assumingMemoryBound(to: UInt8.self))
initWoman(&woman, nds_asset_womanTiles()!.assumingMemoryBound(to: UInt8.self))
DMA.copy(from: nds_asset_manPal(), to: OAM.mainPalette!, size: 512)
DMA.copy(from: nds_asset_womanPal(), to: OAM.subPalette!, size: 512)

while System.mainLoop {
	Keys.scan()
	let keys = Keys.held
	if keys.contains(.start) { break }

	if !keys.isEmpty {
		if keys.contains(.up) {
			if man.y >= 0 { man.y -= 1 }
			if woman.y >= 0 { woman.y -= 1 }
			man.state = W_UP; woman.state = W_UP
		}
		if keys.contains(.left) {
			if man.x >= 0 { man.x -= 1 }
			if woman.x >= 0 { woman.x -= 1 }
			man.state = W_LEFT; woman.state = W_LEFT
		}
		if keys.contains(.right) {
			if man.x <= 256 { man.x += 1 }
			if woman.x <= 256 { woman.x += 1 }
			man.state = W_RIGHT; woman.state = W_RIGHT
		}
		if keys.contains(.down) {
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

	OAM.main.set(id: 0, x: man.x, y: man.y, priority: 0, paletteAlpha: 0,
	             size: SpriteSize_32x32, format: .color256, gfx: man.spriteGfxMem)
	OAM.sub.set(id: 0, x: woman.x, y: woman.y, priority: 0, paletteAlpha: 0,
	            size: SpriteSize_32x32, format: .color256, gfx: woman.spriteGfxMem[woman.gfxFrame])

	System.waitForVBlank()
	OAM.main.update()
	OAM.sub.update()
}
