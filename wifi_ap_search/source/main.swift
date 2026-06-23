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

import CNDS

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
	let gfx = UnsafeRawPointer(nds_sprite_gfx_sub()! + off)
	oamSetGfx(&oamSub, 0, SpriteSize_16x16, SpriteColorFormat_16Color, gfx)
	oamSetHidden(&oamSub, 0, !isActive)
	oamUpdate(&oamSub)
}

func keyPressed(_ c: Int32) {
	if c > 0 { nds_printf_1i("%c", c) }
}

// Read a line from the keyboard; returns the buffer and length (-1 on EOF).
func readLine64() -> ([CChar], Int32) {
	var buf = [CChar](repeating: 0, count: 64)
	let n = buf.withUnsafeMutableBufferPointer { nds_read_line($0.baseAddress, 64) }
	return (buf, n)
}

//---------------------------------------------------------------------------------
// Scan + AP-selection screen. Returns the chosen AP (or nil to retry).
//---------------------------------------------------------------------------------
func findAP() -> UnsafeMutablePointer<WlanBssDesc>? {
	var selected = 0
	var displaytop = 0
	var count: UInt32 = 0
	var aplist: UnsafeMutablePointer<WlanBssDesc>? = nil

	var filter = WlanBssScanFilter()
	filter.channel_mask = 0xFFFFFFFF
	filter.target_bssid = (0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF)

	while true {   // rescan target
		if !wfcBeginScan(&filter) { return nil }
		nds_puts("Scanning APs...\n")

		while pmMainLoop() {
			aplist = wfcGetScanBssList(&count)
			if aplist != nil { break }
			threadWaitForVBlank()
			scanKeys()
			if keysDown() & KEY_START != 0 { exit(0) }
		}

		guard let list = aplist, count != 0 else {
			nds_puts("No APs detected\n")
			return nil
		}

		var rescan = false
		while pmMainLoop() {
			threadWaitForVBlank()
			scanKeys()
			let pressed = keysDown()
			if pressed & KEY_START != 0 { exit(0) }
			if pressed & KEY_A != 0 { return list + selected }

			consoleClear()
			if pressed & KEY_R != 0 { rescan = true; break }

			nds_printf_1i("%u APs detected (R = rescan)\n\n", Int32(bitPattern: count))

			var displayend = displaytop + 10
			if displayend > Int(count) { displayend = Int(count) }

			for i in displaytop ..< displayend {
				let ap = list + i
				var ssidBuf = [CChar](repeating: 0, count: 33)
				nds_ap_get_ssid(ap, &ssidBuf)

				nds_puts(i == selected ? "*" : " ")
				if nds_ap_ssid_len(ap) != 0 {
					ssidBuf.withUnsafeBufferPointer { nds_printf_str("%.29s", $0.baseAddress) }
				} else {
					nds_puts("-- Hidden SSID --")
				}
				nds_puts("\n  ")
				nds_puts(signalStrength[Int(wlanCalcSignalStrength(nds_ap_rssi(ap)))])
				nds_puts(" Type:")
				nds_puts(authTypes[Int(authMaskToType(nds_ap_auth_mask(ap)).rawValue)])
				nds_puts("\n")
			}

			if pressed & KEY_UP != 0 {
				selected -= 1
				if selected < 0 { selected = 0 }
				if selected < displaytop { displaytop = selected }
			}
			if pressed & KEY_DOWN != 0 {
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
	let showMsg = showMsgIn && pmMainLoop()
	if showMsg { nds_puts("Press A to try again, B to quit\n") }

	while pmMainLoop() {
		threadWaitForVBlank()
		scanKeys()
		let pressed = keysDown()
		if pressed & KEY_A != 0 { return true }
		if pressed & (KEY_B | KEY_START) != 0 { break }
	}
	return false
}

//---------------------------------------------------------------------------------
// Setup
//---------------------------------------------------------------------------------
_ = consoleDemoInit()

vramSetBankD(VRAM_D_SUB_SPRITE)
oamInit(&oamSub, SpriteMapping_Bmp_1D_128, false)

dmaCopy(nds_asset_wifiiconPal(),   nds_sprite_palette_sub(), UInt32(wifiiconPalLen))
dmaCopy(nds_asset_wifiiconTiles(), nds_sprite_gfx_sub(),     UInt32(wifiiconTilesLen))

oamSet(&oamSub, 0, 256 - 16, 0, 0, 0, SpriteSize_16x16, SpriteColorFormat_16Color,
       nds_sprite_gfx_sub(), -1, false, false, false, false, false)
oamSetHidden(&oamSub, 0, true)
irqSet(IRQ_VBLANK, wifiSignalIsr)

let kb = keyboardDemoInit()
kb!.pointee.OnKeyPressed = keyPressed

if !Wifi_InitDefault(false) {
	nds_puts("Wifi init fail\n")
	_ = die(false)
} else {
	var auth = WlanAuthData()

	repeat {
		consoleClear()
		consoleSetWindow(nil, 0, 0, 32, 24)

		guard let ap = findAP() else { continue }

		consoleClear()
		consoleSetWindow(nil, 0, 0, 32, 10)

		// hidden SSID: prompt for the name
		if nds_ap_ssid_len(ap) == 0 {
			nds_puts("Enter hidden SSID name\n")
			while true {
				let (buf, len) = readLine64()
				if len < 0 { exit(0) }
				if len > 0 && len <= Int32(WLAN_MAX_SSID_LEN) {
					buf.withUnsafeBufferPointer { nds_ap_set_ssid(ap, $0.baseAddress, UInt32(len)) }
					break
				}
				nds_puts("Invalid SSID\n")
			}
		}

		var ssidBuf = [CChar](repeating: 0, count: 33)
		nds_ap_get_ssid(ap, &ssidBuf)
		ssidBuf.withUnsafeBufferPointer { nds_printf_str("Connecting to %s\n", $0.baseAddress) }

		nds_ap_set_auth_type(ap, Int32(authMaskToType(nds_ap_auth_mask(ap)).rawValue))
		nds_auth_clear(&auth)

		let authType = authMaskToType(nds_ap_auth_mask(ap))
		if authType.rawValue != WlanBssAuthType_Open.rawValue {
			nds_printf_str("Enter %s key\n", authTypes[Int(authType.rawValue)])
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
				if !ok { nds_puts("Invalid key!\n"); continue }

				nds_ap_set_auth_type(ap, Int32(finalType.rawValue))
				if authType.rawValue < WlanBssAuthType_WPA_PSK_TKIP.rawValue {
					buf.withUnsafeBufferPointer { nds_auth_set_wep(&auth, $0.baseAddress, UInt32(len)) }
				} else {
					nds_puts("Deriving PMK, please wait\n")
					buf.withUnsafeBufferPointer { keyPtr in
						ssidBuf.withUnsafeBufferPointer { ssidPtr in
							_ = wfcDeriveWpaKey(&auth, ssidPtr.baseAddress, nds_ap_ssid_len(ap),
							                    keyPtr.baseAddress, UInt32(len))
						}
					}
				}
				break
			}
		}

		if !wfcBeginConnect(ap, &auth) { continue }

		var isConnect = false
		while pmMainLoop() {
			threadWaitForVBlank()
			scanKeys()
			if keysDown() & KEY_START != 0 { exit(0) }

			let status = Wifi_AssocStatus()
			consoleClear()
			nds_printf_str("%s\n", connStatus[Int(status)])

			isConnect = status == Int32(ASSOCSTATUS_ASSOCIATED.rawValue)
			if isConnect || status == Int32(ASSOCSTATUS_DISCONNECTED.rawValue) { break }
		}

		if isConnect {
			let ip = Wifi_GetIP()
			nds_printf_4i("Our IP: %u.%u.%u.%u\n",
			              Int32(ip & 0xFF), Int32((ip >> 8) & 0xFF),
			              Int32((ip >> 16) & 0xFF), Int32((ip >> 24) & 0xFF))

			while true {
				nds_puts("Enter domain name\n")
				let (buf, len) = readLine64()
				if len < 0 { break }
				if len == 0 { break }
				let host = buf.withUnsafeBufferPointer { gethostbyname($0.baseAddress) }
				if let h = host, let addr0 = h.pointee.h_addr_list[0] {
					let inaddr = addr0.withMemoryRebound(to: in_addr.self, capacity: 1) { $0.pointee }
					nds_printf_str("Domain IP: %s\n", inet_ntoa(inaddr))
				} else {
					nds_puts("Could not resolve domain\n")
				}
			}

			_ = Wifi_DisconnectAP()
		}
	} while die(true)
}

while pmMainLoop() { threadWaitForVBlank() }
