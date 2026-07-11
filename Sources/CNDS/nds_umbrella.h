//---------------------------------------------------------------------------------
// nds_umbrella.h -- single header exposed to Swift as the `CNDS` module.
//---------------------------------------------------------------------------------
#ifndef SWIFT_NDS_UMBRELLA_H
#define SWIFT_NDS_UMBRELLA_H

#include <nds.h>
#include <nds/arm9/postest.h>   // 3D position test (picking) -- not pulled in by nds.h
#include <nds/arm9/image.h>     // loadPCX / image8to16 / sImage
#include <gl2d.h>               // Easy GL2D helper library (ships with libnds)
#include <stdlib.h>             // rand(), malloc(), ...
#include <dswifi9.h>            // Wifi_InitDefault / Wifi_GetIPInfo (dswifi examples)
#include <wfc.h>                // wfcBeginScan / wfcBeginConnect (ap_search)
#include <arpa/inet.h>          // inet_ntoa, struct in_addr
#include <sys/socket.h>         // socket / connect / send / recv (dswifi httpget)
#include <netdb.h>              // gethostbyname, struct hostent
#include "shim.h"

#endif // SWIFT_NDS_UMBRELLA_H
