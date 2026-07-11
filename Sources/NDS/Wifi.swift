//===----------------------------------------------------------------------===//
// Wifi.swift -- dswifi + the WFC connection manager.
//
// Wraps the dswifi9 entry points and the calico `wfc*` scan/connect API. The
// `WlanBssDesc` / `WlanAuthData` structs have unions and fixed char[] SSIDs that
// import awkwardly, so the shim exposes typed field accessors (`nds_ap_*` /
// `nds_auth_*`); those are surfaced here as extensions.
//===----------------------------------------------------------------------===//

public enum Wifi {
    /// Bring up wifi, optionally using the firmware's stored WFC settings
    /// (`Wifi_InitDefault`). Returns true on success.
    @discardableResult
    @inline(__always) public static func initDefault(useFirmwareSettings: Bool) -> Bool {
        Wifi_InitDefault(useFirmwareSettings)
    }

    /// Current association status (`Wifi_AssocStatus`; compare to `ASSOCSTATUS_ASSOCIATED`).
    @inline(__always) public static var assocStatus: Int32 { Wifi_AssocStatus() }
    @inline(__always) public static func disconnect() { Wifi_DisconnectAP() }

    /// The current IPv4 address as a raw 32-bit value (`Wifi_GetIP`).
    @inline(__always) public static var ip: UInt { Wifi_GetIP() }

    /// Fetch the full IP configuration (`Wifi_GetIPInfo`); returns the address and
    /// fills the gateway / netmask / DNS out-parameters.
    @inline(__always)
    public static func ipInfo(gateway: UnsafeMutablePointer<in_addr>, netmask: UnsafeMutablePointer<in_addr>,
                              dns1: UnsafeMutablePointer<in_addr>, dns2: UnsafeMutablePointer<in_addr>) -> in_addr {
        Wifi_GetIPInfo(gateway, netmask, dns1, dns2)
    }

    // MARK: WFC scan / connect

    /// Begin an access-point scan (`wfcBeginScan`).
    @discardableResult
    @inline(__always) public static func beginScan(filter: UnsafePointer<WlanBssScanFilter>) -> Bool { wfcBeginScan(filter) }

    /// The result list from the last scan, plus its length (`wfcGetScanBssList`).
    @inline(__always) public static func scanResults() -> (list: UnsafeMutablePointer<WlanBssDesc>?, count: UInt32) {
        var count: UInt32 = 0
        let list = wfcGetScanBssList(&count)
        return (list, count)
    }

    /// Derive WPA key material from an SSID + passphrase (`wfcDeriveWpaKey`).
    @discardableResult
    @inline(__always)
    public static func deriveWpaKey(into auth: UnsafeMutablePointer<WlanAuthData>,
                                    ssid: UnsafePointer<CChar>, ssidLen: UInt32,
                                    key: UnsafePointer<CChar>, keyLen: UInt32) -> Bool {
        wfcDeriveWpaKey(auth, ssid, ssidLen, key, keyLen)
    }

    /// Connect to an access point with the given auth data (`wfcBeginConnect`).
    @discardableResult
    @inline(__always)
    public static func beginConnect(to bss: UnsafePointer<WlanBssDesc>, auth: UnsafePointer<WlanAuthData>) -> Bool {
        wfcBeginConnect(bss, auth)
    }
}

// MARK: - Access-point description (shim-backed field access)

public extension UnsafeMutablePointer where Pointee == WlanBssDesc {
    /// Copy the SSID out as a null-terminated C string (`nds_ap_get_ssid`).
    @inline(__always) func getSSID(into out: UnsafeMutablePointer<CChar>) { nds_ap_get_ssid(self, out) }
    /// Set the SSID (`nds_ap_set_ssid`).
    @inline(__always) func setSSID(_ s: UnsafePointer<CChar>, length: UInt32) { nds_ap_set_ssid(self, s, length) }
    /// The SSID length in bytes (`nds_ap_ssid_len`).
    @inline(__always) var ssidLength: UInt32 { nds_ap_ssid_len(self) }
    /// The supported authentication types bitmask (`nds_ap_auth_mask`).
    @inline(__always) var authMask: UInt32 { nds_ap_auth_mask(self) }
    /// Received signal strength (`nds_ap_rssi`).
    @inline(__always) var rssi: UInt32 { nds_ap_rssi(self) }
    /// Force a specific auth type (`nds_ap_set_auth_type`).
    @inline(__always) func setAuthType(_ type: Int32) { nds_ap_set_auth_type(self, type) }
}

public extension UnsafeMutablePointer where Pointee == WlanAuthData {
    /// Clear the auth data to an open (no-key) configuration (`nds_auth_clear`).
    @inline(__always) func clear() { nds_auth_clear(self) }
    /// Set a WEP key (`nds_auth_set_wep`).
    @inline(__always) func setWEP(_ key: UnsafePointer<CChar>, length: UInt32) { nds_auth_set_wep(self, key, length) }
}
