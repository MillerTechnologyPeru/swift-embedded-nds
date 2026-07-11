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

import NDS

Console.demoInit()

Console.print("\n\n\tSimple Wifi Connection Demo\n\n")
Console.print("Connecting via WFC data ...\n")

if !Wifi.initDefault(useFirmwareSettings: true) {   // WFC_CONNECT
	Console.print("Failed to connect!")
} else {
	Console.print("Connected\n\n")

	var gateway = in_addr(), mask = in_addr(), dns1 = in_addr(), dns2 = in_addr()
	var ip = Wifi.ipInfo(gateway: &gateway, netmask: &mask, dns1: &dns1, dns2: &dns2)

	// inet_ntoa returns a pointer to a shared static buffer, so format and print
	// one address at a time before the next call overwrites it.
	Console.printf("ip     : %s\n", inet_ntoa(ip))
	Console.printf("gateway: %s\n", inet_ntoa(gateway))
	Console.printf("mask   : %s\n", inet_ntoa(mask))
	Console.printf("dns1   : %s\n", inet_ntoa(dns1))
	Console.printf("dns2   : %s\n", inet_ntoa(dns2))
}

while System.mainLoop {
	System.waitForVBlank()
	Keys.scan()
	if Keys.down.contains(.start) { break }
}
