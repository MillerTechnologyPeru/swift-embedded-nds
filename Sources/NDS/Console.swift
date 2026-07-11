//===----------------------------------------------------------------------===//
// Console.swift -- the text console(s).
//
// Printing goes through the shim's fixed-arity wrappers (`nds_puts` /
// `nds_printf_*`) because Embedded Swift can import but not call C variadics; a
// Swift string literal bridges to the `const char*` these take, so
// `Console.print("Hello\n")` reads naturally. The formatted helpers cover the
// argument shapes the examples need.
//===----------------------------------------------------------------------===//

public enum Console {
    /// Initialize the default full-screen console on the sub engine
    /// (`consoleDemoInit`). Returns the console it set up.
    @discardableResult
    @inline(__always) public static func demoInit() -> UnsafeMutablePointer<PrintConsole>? {
        consoleDemoInit()
    }

    /// Full `consoleInit`: bind a console to a background layer/engine.
    @discardableResult
    @inline(__always)
    public static func initialize(_ console: UnsafeMutablePointer<PrintConsole>?, layer: Int32,
                                  kind: Background.Kind, size: BgSize, mapBase: Int32, tileBase: Int32,
                                  mainDisplay: Bool, loadGraphics: Bool = true) -> UnsafeMutablePointer<PrintConsole>? {
        consoleInit(console, layer, kind.c, size, mapBase, tileBase, mainDisplay, loadGraphics)
    }

    /// Make `console` the current print target (`consoleSelect`).
    @discardableResult
    @inline(__always) public static func select(_ console: UnsafeMutablePointer<PrintConsole>?) -> UnsafeMutablePointer<PrintConsole>? {
        consoleSelect(console)
    }

    @inline(__always) public static var current: UnsafeMutablePointer<PrintConsole>? { consoleGetDefault() }
    @inline(__always) public static func clear() { consoleClear() }

    /// Restrict output to a sub-rectangle of the console (`consoleSetWindow`).
    @inline(__always) public static func setWindow(_ console: UnsafeMutablePointer<PrintConsole>?, x: Int32, y: Int32, width: Int32, height: Int32) {
        consoleSetWindow(console, x, y, width, height)
    }

    /// Replace a console's font (`consoleSetFont`).
    @inline(__always) public static func setFont(_ console: UnsafeMutablePointer<PrintConsole>?, _ font: UnsafeMutablePointer<ConsoleFont>?) {
        consoleSetFont(console, font)
    }

    // MARK: Printing (via the variadic-safe shim)

    /// Print a string (`nds_puts`). A Swift string literal bridges to the C
    /// `const char*` this expects, so `Console.print("Hi\n")` just works.
    @inline(__always) public static func print(_ s: UnsafePointer<CChar>) { nds_puts(s) }

    /// Formatted print with one integer argument (`iprintf`, e.g. `%d`/`%x`).
    @inline(__always) public static func printf(_ format: UnsafePointer<CChar>, _ a: Int32) { nds_printf_1i(format, a) }
    @inline(__always) public static func printf(_ format: UnsafePointer<CChar>, _ a: Int32, _ b: Int32) { nds_printf_2i(format, a, b) }
    @inline(__always) public static func printf(_ format: UnsafePointer<CChar>, _ a: Int32, _ b: Int32, _ c: Int32) { nds_printf_3i(format, a, b, c) }
    @inline(__always) public static func printf(_ format: UnsafePointer<CChar>, _ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32) { nds_printf_4i(format, a, b, c, d) }

    /// Formatted print with floating-point arguments (`printf`, for `%f`).
    @inline(__always) public static func printf(_ format: UnsafePointer<CChar>, _ a: Double) { nds_printf_1f(format, a) }
    @inline(__always) public static func printf(_ format: UnsafePointer<CChar>, _ a: Double, _ b: Double) { nds_printf_2f(format, a, b) }

    /// Formatted print with one string argument (`iprintf`, `%s`).
    @inline(__always) public static func printf(_ format: UnsafePointer<CChar>, _ s: UnsafePointer<CChar>) { nds_printf_str(format, s) }

    /// Read a whitespace-delimited string from stdin into `buffer` (`iscanf`,
    /// via the shim's `nds_scanf_str`).
    @inline(__always) public static func scanString(into buffer: UnsafeMutablePointer<CChar>) { nds_scanf_str(buffer) }
}
