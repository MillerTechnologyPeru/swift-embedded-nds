//---------------------------------------------------------------------------------
// nds_umbrella.h -- single header exposed to Swift as the `CNDS` module.
//---------------------------------------------------------------------------------
#ifndef SWIFT_NDS_UMBRELLA_H
#define SWIFT_NDS_UMBRELLA_H

#include <nds.h>
#include <nds/arm9/postest.h>   // 3D position test (picking) -- not pulled in by nds.h
#include <gl2d.h>               // Easy GL2D helper library (ships with libnds)
#include <stdlib.h>             // rand(), malloc(), ...
#include "shim.h"

#endif // SWIFT_NDS_UMBRELLA_H
