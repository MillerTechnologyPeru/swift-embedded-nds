//---------------------------------------------------------------------------------
//
//  Swift port of the libnds dswifi autoconnect example.
//
//  Connects to the access point stored in the DS firmware's Wi-Fi Connection
//  (WFC) settings, then prints the assigned IP / gateway / netmask / DNS.
//
//  (Requires Wi-Fi config in the DS firmware and emulator/hardware network
//  access; in melonDS, configure online connectivity + a WFC AP.)
//
//---------------------------------------------------------------------------------

import CNDS

_ = consoleDemoInit()

nds_puts("\n\n\tSimple Wifi Connection Demo\n\n")
nds_puts("Connecting via WFC data ...\n")

if !Wifi_InitDefault(true) {   // WFC_CONNECT
	nds_puts("Failed to connect!")
} else {
	nds_puts("Connected\n\n")

	var gateway = in_addr(), mask = in_addr(), dns1 = in_addr(), dns2 = in_addr()
	var ip = Wifi_GetIPInfo(&gateway, &mask, &dns1, &dns2)

	// inet_ntoa returns a pointer to a shared static buffer, so format and print
	// one address at a time before the next call overwrites it.
	nds_printf_str("ip     : %s\n", inet_ntoa(ip))
	nds_printf_str("gateway: %s\n", inet_ntoa(gateway))
	nds_printf_str("mask   : %s\n", inet_ntoa(mask))
	nds_printf_str("dns1   : %s\n", inet_ntoa(dns1))
	nds_printf_str("dns2   : %s\n", inet_ntoa(dns2))
}

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
