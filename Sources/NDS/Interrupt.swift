//===----------------------------------------------------------------------===//
// Interrupt.swift -- hardware interrupts (IRQs).
//
// An interrupt service routine runs in the CPU's IRQ mode; a non-capturing
// top-level Swift function (or non-capturing closure) bridges to the C
// `IrqHandler` = `void(*)(void)` type that `irqSet` expects. The `IRQ_*` bits
// are integer macros; we gather them into an `IRQ` OptionSet.
//===----------------------------------------------------------------------===//

/// A set of interrupt sources (an `IRQ_*` bitmask).
public struct IRQ: OptionSet {
    public let rawValue: UInt32
    @inline(__always) public init(rawValue: UInt32) { self.rawValue = rawValue }

    public static let vblank = IRQ(rawValue: 1 << 0)
    public static let hblank = IRQ(rawValue: 1 << 1)
    public static let vcount = IRQ(rawValue: 1 << 2)
    public static let timer0 = IRQ(rawValue: 1 << 3)
    public static let timer1 = IRQ(rawValue: 1 << 4)
    public static let timer2 = IRQ(rawValue: 1 << 5)
    public static let timer3 = IRQ(rawValue: 1 << 6)
    public static let dma0   = IRQ(rawValue: 1 << 8)
    public static let dma1   = IRQ(rawValue: 1 << 9)
    public static let dma2   = IRQ(rawValue: 1 << 10)
    public static let dma3   = IRQ(rawValue: 1 << 11)
    public static let keypad = IRQ(rawValue: 1 << 12)
    public static let slot2  = IRQ(rawValue: 1 << 13)
    public static let pxiSync = IRQ(rawValue: 1 << 16)
    public static let pxiSend = IRQ(rawValue: 1 << 17)
    public static let pxiRecv = IRQ(rawValue: 1 << 18)
    public static let slot1Transfer = IRQ(rawValue: 1 << 19)
    public static let slot1IReq = IRQ(rawValue: 1 << 20)

    /// The interrupt for timer channel `n` (0...3).
    @inline(__always) public static func timer(_ n: UInt32) -> IRQ { IRQ(rawValue: 1 << (3 + n)) }
    /// The interrupt for DMA channel `n` (0...3).
    @inline(__always) public static func dma(_ n: UInt32) -> IRQ { IRQ(rawValue: 1 << (8 + n)) }

    /// Install `handler` as the ISR for the interrupt(s) in this set, then
    /// enable them (`irqSet` + `irqEnable`). The handler must not capture.
    @inline(__always)
    public func set(_ handler: @convention(c) () -> Void) {
        irqSet(rawValue, handler)
        irqEnable(rawValue)
    }

    /// Install the ISR without enabling the interrupt (`irqSet`).
    @inline(__always)
    public func setHandler(_ handler: @convention(c) () -> Void) { irqSet(rawValue, handler) }

    @inline(__always) public func enable()  { irqEnable(rawValue) }
    @inline(__always) public func disable() { irqDisable(rawValue) }
    @inline(__always) public func clear()   { irqClear(rawValue) }
}
