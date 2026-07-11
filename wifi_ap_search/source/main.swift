//---------------------------------------------------------------------------------
//
//  Swift port of the libnds dswifi ap_search example (dovoto).
//
//  Scans for nearby access points, lets you pick one (with a live signal-strength
//  icon sprite driven by a VBlank IRQ), prompts for a hidden SSID / WEP / WPA key
//  via the on-screen keyboard, connects, then resolves domain names you type.
//
//  Controls: Up/Down select, A connect, R rescan, START quit.
//
//---------------------------------------------------------------------------------

import NDS

let signalStrength = ["[   ]", "[.  ]", "[.i ]", "[.iI]"]
let authTypes = [
	"Open", "WEP", "WEP", "WEP",
	"WPA-PSK-TKIP", "WPA-PSK-AES", "WPA2-PSK-TKIP", "WPA2-PSK-AES",
]
let connStatus = [
	"Disconnected :(", "Searching...", "Associating...",
	"Obtaining IP address...", "Connected!",
]

@inline(__always) func authMaskToType(_ mask: UInt32) -> WlanBssAuthType {
	mask != 0 ? WlanBssAuthType(UInt32(31 - mask.leadingZeroBitCount)) : WlanBssAuthType_Open
}

//---------------------------------------------------------------------------------
// Signal-strength icon sprite, refreshed every VBlank.
//---------------------------------------------------------------------------------
func wifiSignalIsr() {
	let level = Int(wlmgrGetSignalStrength())
	let isActive = wlmgrGetState().rawValue >= WlMgrState_Associating.rawValue

	// pick the matching 16x16 frame out of the four loaded into sub sprite VRAM
	let off = level * Int(wifiiconTilesLen) / (4 * MemoryLayout<UInt16>.size)
	let gfx = UnsafeRawPointer(OAM.subGfx! + off)
	OAM.sub.setGfx(id: 0, size: SpriteSize_16x16, format: .color16, gfx: gfx)
	OAM.sub.setHidden(id: 0, !isActive)
	OAM.sub.update()
}

func keyPressed(_ c: Int32) {
	if c > 0 { Console.printf("%c", c) }
}

// Read a line from the keyboard; returns the buffer and length (-1 on EOF).
func readLine64() -> ([CChar], Int32) {
	var buf = [CChar](repeating: 0, count: 64)
	let n = buf.withUnsafeMutableBufferPointer { Filesystem.readLine(into: $0.baseAddress!, size: 64) }
	return (buf, n)
}

//---------------------------------------------------------------------------------
// Scan + AP-selection screen. Returns the chosen AP (or nil to retry).
//---------------------------------------------------------------------------------
func findAP() -> UnsafeMutablePointer<WlanBssDesc>? {
	var selected = 0
	var displaytop = 0

	var filter = WlanBssScanFilter()
	filter.channel_mask = 0xFFFFFFFF
	filter.target_bssid = (0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF)

	while true {   // rescan target
		if !Wifi.beginScan(filter: &filter) { return nil }
		Console.print("Scanning APs...\n")

		var list: UnsafeMutablePointer<WlanBssDesc>? = nil
		var count: UInt32 = 0
		while System.mainLoop {
			let r = Wifi.scanResults()
			if r.list != nil { list = r.list; count = r.count; break }
			System.waitForVBlank()
			Keys.scan()
			if Keys.down.contains(.start) { exit(0) }
		}

		guard let aplist = list, count != 0 else {
			Console.print("No APs detected\n")
			return nil
		}

		var rescan = false
		while System.mainLoop {
			System.waitForVBlank()
			Keys.scan()
			let pressed = Keys.down
			if pressed.contains(.start) { exit(0) }
			if pressed.contains(.a) { return aplist + selected }

			Console.clear()
			if pressed.contains(.r) { rescan = true; break }

			Console.printf("%u APs detected (R = rescan)\n\n", Int32(bitPattern: count))

			var displayend = displaytop + 10
			if displayend > Int(count) { displayend = Int(count) }

			for i in displaytop ..< displayend {
				let ap = aplist + i
				var ssidBuf = [CChar](repeating: 0, count: 33)
				ap.getSSID(into: &ssidBuf)

				Console.print(i == selected ? "*" : " ")
				if ap.ssidLength != 0 {
					ssidBuf.withUnsafeBufferPointer { Console.printf("%.29s", $0.baseAddress!) }
				} else {
					Console.print("-- Hidden SSID --")
				}
				Console.print("\n  ")
				Console.print(signalStrength[Int(wlanCalcSignalStrength(ap.rssi))])
				Console.print(" Type:")
				Console.print(authTypes[Int(authMaskToType(ap.authMask).rawValue)])
				Console.print("\n")
			}

			if pressed.contains(.up) {
				selected -= 1
				if selected < 0 { selected = 0 }
				if selected < displaytop { displaytop = selected }
			}
			if pressed.contains(.down) {
				selected += 1
				if selected >= Int(count) { selected = Int(count) - 1 }
				displaytop = selected - 9
				if displaytop < 0 { displaytop = 0 }
			}
		}
		if !rescan { return nil }
	}
}

//---------------------------------------------------------------------------------
// "Press A to retry / B to quit" prompt between connection attempts.
//---------------------------------------------------------------------------------
func die(_ showMsgIn: Bool) -> Bool {
	let showMsg = showMsgIn && System.mainLoop
	if showMsg { Console.print("Press A to try again, B to quit\n") }

	while System.mainLoop {
		System.waitForVBlank()
		Keys.scan()
		let pressed = Keys.down
		if pressed.contains(.a) { return true }
		if !pressed.intersection([.b, .start]).isEmpty { break }
	}
	return false
}

//---------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------
Console.demoInit()

Video.setBankD(VRAM_D_SUB_SPRITE)
OAM.sub.initialize(mapping: SpriteMapping_Bmp_1D_128)

DMA.copy(from: nds_asset_wifiiconPal(),   to: OAM.subPalette!, size: UInt32(wifiiconPalLen))
DMA.copy(from: nds_asset_wifiiconTiles(), to: OAM.subGfx!,     size: UInt32(wifiiconTilesLen))

OAM.sub.set(id: 0, x: 256 - 16, y: 0, priority: 0, paletteAlpha: 0, size: SpriteSize_16x16, format: .color16,
            gfx: OAM.subGfx)
OAM.sub.setHidden(id: 0, true)
IRQ.vblank.set(wifiSignalIsr)

let kb = OnScreenKeyboard.demoInit()
kb!.pointee.OnKeyPressed = keyPressed

if !Wifi.initDefault(useFirmwareSettings: false) {
	Console.print("Wifi init fail\n")
	_ = die(false)
} else {
	var auth = WlanAuthData()

	repeat {
		Console.clear()
		Console.setWindow(nil, x: 0, y: 0, width: 32, height: 24)

		guard let ap = findAP() else { continue }

		Console.clear()
		Console.setWindow(nil, x: 0, y: 0, width: 32, height: 10)

		// hidden SSID: prompt for the name
		if ap.ssidLength == 0 {
			Console.print("Enter hidden SSID name\n")
			while true {
				let (buf, len) = readLine64()
				if len < 0 { exit(0) }
				if len > 0 && len <= Int32(WLAN_MAX_SSID_LEN) {
					buf.withUnsafeBufferPointer { ap.setSSID($0.baseAddress!, length: UInt32(len)) }
					break
				}
				Console.print("Invalid SSID\n")
			}
		}

		var ssidBuf = [CChar](repeating: 0, count: 33)
		ap.getSSID(into: &ssidBuf)
		ssidBuf.withUnsafeBufferPointer { Console.printf("Connecting to %s\n", $0.baseAddress!) }

		ap.setAuthType(Int32(authMaskToType(ap.authMask).rawValue))
		nds_auth_clear(&auth)

		let authType = authMaskToType(ap.authMask)
		if authType.rawValue != WlanBssAuthType_Open.rawValue {
			Console.printf("Enter %s key\n", authTypes[Int(authType.rawValue)])
			var finalType = authType
			while true {
				let (buf, len) = readLine64()
				if len < 0 { exit(0) }
				var ok = true
				if authType.rawValue < WlanBssAuthType_WPA_PSK_TKIP.rawValue {
					switch Int(len) {
					case Int(WLAN_WEP_40_LEN):  finalType = WlanBssAuthType_WEP_40
					case Int(WLAN_WEP_104_LEN): finalType = WlanBssAuthType_WEP_104
					case Int(WLAN_WEP_128_LEN): finalType = WlanBssAuthType_WEP_128
					default: ok = false
					}
				} else if len < 1 || len >= Int32(WLAN_WPA_PSK_LEN) {
					ok = false
				}
				if !ok { Console.print("Invalid key!\n"); continue }

				ap.setAuthType(Int32(finalType.rawValue))
				if authType.rawValue < WlanBssAuthType_WPA_PSK_TKIP.rawValue {
					buf.withUnsafeBufferPointer { nds_auth_set_wep(&auth, $0.baseAddress, UInt32(len)) }
				} else {
					Console.print("Deriving PMK, please wait\n")
					buf.withUnsafeBufferPointer { keyPtr in
						ssidBuf.withUnsafeBufferPointer { ssidPtr in
							_ = Wifi.deriveWpaKey(into: &auth, ssid: ssidPtr.baseAddress!, ssidLen: ap.ssidLength,
							                      key: keyPtr.baseAddress!, keyLen: UInt32(len))
						}
					}
				}
				break
			}
		}

		if !Wifi.beginConnect(to: ap, auth: &auth) { continue }

		var isConnect = false
		while System.mainLoop {
			System.waitForVBlank()
			Keys.scan()
			if Keys.down.contains(.start) { exit(0) }

			let status = Wifi.assocStatus
			Console.clear()
			Console.printf("%s\n", connStatus[Int(status)])

			isConnect = status == Int32(ASSOCSTATUS_ASSOCIATED.rawValue)
			if isConnect || status == Int32(ASSOCSTATUS_DISCONNECTED.rawValue) { break }
		}

		if isConnect {
			let ip = Wifi.ip
			Console.printf("Our IP: %u.%u.%u.%u\n",
			               Int32(ip & 0xFF), Int32((ip >> 8) & 0xFF),
			               Int32((ip >> 16) & 0xFF), Int32((ip >> 24) & 0xFF))

			while true {
				Console.print("Enter domain name\n")
				let (buf, len) = readLine64()
				if len < 0 { break }
				if len == 0 { break }
				let host = buf.withUnsafeBufferPointer { gethostbyname($0.baseAddress) }
				if let h = host, let addr0 = h.pointee.h_addr_list[0] {
					let inaddr = addr0.withMemoryRebound(to: in_addr.self, capacity: 1) { $0.pointee }
					Console.printf("Domain IP: %s\n", inet_ntoa(inaddr))
				} else {
					Console.print("Could not resolve domain\n")
				}
			}

			_ = Wifi.disconnect()
		}
	} while die(true)
}

while System.mainLoop { System.waitForVBlank() }
