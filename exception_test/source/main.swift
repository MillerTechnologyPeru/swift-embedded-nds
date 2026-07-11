//---------------------------------------------------------------------------------
//
//  Swift port of the libnds exceptionTest example.
//
//  The default exception handler displays the exception type (data abort or
//  undefined instruction). Relate the faulting `pc` back to your code with:
//
//      arm-none-eabi-addr2line -e exception_test.elf <address>
//
//---------------------------------------------------------------------------------

import NDS

// install the default exception handler
Exceptions.installDefaultHandler()

// generate an exception: store to a low, protected address
UnsafeMutablePointer<UInt32>(bitPattern: 8192)!.pointee = 100

while System.mainLoop {
	System.waitForVBlank()
}
