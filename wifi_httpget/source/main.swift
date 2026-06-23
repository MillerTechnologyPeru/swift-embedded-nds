//---------------------------------------------------------------------------------
//
//  Swift port of the libnds dswifi httpget example.
//
//  Connects via the firmware WFC settings, resolves a hostname, opens a TCP
//  socket to port 80, sends a raw HTTP/1.1 GET, and prints the response.
//
//---------------------------------------------------------------------------------

import CNDS

// htons: host (DS little-endian) -> network byte order. (Macro, doesn't import.)
@inline(__always) func htons(_ x: UInt16) -> UInt16 { x.byteSwapped }

func getHTTP(_ url: String) {
	let request =
		"GET /dswifi/example1.php HTTP/1.1\r\n" +
		"Host: www.akkit.org\r\n" +
		"User-Agent: Nintendo DS\r\n\r\n"

	// Resolve the server address.
	guard let myhost = gethostbyname(url), myhost.pointee.h_addr_list[0] != nil else {
		nds_puts("DNS lookup failed!\n")
		return
	}
	nds_puts("Found IP Address!\n")

	// Create a TCP socket.
	let mySocket = socket(AF_INET, SOCK_STREAM, 0)
	nds_puts("Created Socket!\n")

	// Connect to the resolved address on port 80.
	var sain = sockaddr_in()
	sain.sin_family = sa_family_t(AF_INET)
	sain.sin_port = htons(80)
	sain.sin_addr.s_addr = myhost.pointee.h_addr_list[0]!
		.withMemoryRebound(to: in_addr_t.self, capacity: 1) { $0.pointee }

	withUnsafePointer(to: &sain) { p in
		p.withMemoryRebound(to: sockaddr.self, capacity: 1) { sp in
			_ = connect(mySocket, sp, socklen_t(MemoryLayout<sockaddr_in>.size))
		}
	}
	nds_puts("Connected to server!\n")

	// Send the request.
	var reqBytes = Array(request.utf8)
	reqBytes.withUnsafeBytes { _ = send(mySocket, $0.baseAddress, reqBytes.count, 0) }
	nds_puts("Sent our request!\n")
	nds_puts("Printing incoming data:\n")

	// Print incoming data until the server closes the connection.
	var buffer = [CChar](repeating: 0, count: 256)
	while true {
		let recvd = buffer.withUnsafeMutableBytes { recv(mySocket, $0.baseAddress, 255, 0) }
		if recvd == 0 { break }            // 0 == connection closed
		if recvd > 0 {
			buffer[Int(recvd)] = 0         // null-terminate
			buffer.withUnsafeBufferPointer { nds_printf_str("%s", $0.baseAddress) }
		}
	}

	nds_puts("Other side closed connection!")
	_ = shutdown(mySocket, 0)
	_ = closesocket(mySocket)
}

_ = consoleDemoInit()

nds_puts("\n\n\tSimple Wifi Connection Demo\n\n")
nds_puts("Connecting via WFC data ...\n")

if !Wifi_InitDefault(true) {   // WFC_CONNECT
	nds_puts("Failed to connect!")
} else {
	nds_puts("Connected\n\n")
	getHTTP("www.akkit.org")
}

while pmMainLoop() {
	threadWaitForVBlank()
	scanKeys()
	if keysDown() & KEY_START != 0 { break }
}
