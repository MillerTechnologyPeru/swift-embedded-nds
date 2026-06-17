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

import CNDS

// install the default exception handler
defaultExceptionHandler()

// generate an exception: store to a low, protected address
UnsafeMutablePointer<UInt32>(bitPattern: 8192)!.pointee = 100

while pmMainLoop() {
	threadWaitForVBlank()
}
