//===----------------------------------------------------------------------===//
// Exceptions.swift -- CPU exception handling / crash dumps.
//
// Installing the default handler shows a "guru meditation" register dump on a
// crash instead of hanging silently -- useful when debugging.
//===----------------------------------------------------------------------===//

public enum Exceptions {
    /// Install libnds' default crash-dump handler (`defaultExceptionHandler`).
    @inline(__always) public static func installDefaultHandler() { defaultExceptionHandler() }

    /// Install a custom exception handler (`setExceptionHandler`). Non-capturing.
    @inline(__always) public static func setHandler(_ handler: ExcptHandler) { setExceptionHandler(handler) }
}
