//===----------------------------------------------------------------------===//
// Sound.swift -- the hardware sound channels (PCM samples, PSG, noise, mic).
//
// The `SoundFormat` / `DutyCycle` / `MicFormat` types are typedefs of calico's
// `SoundFmt` / `SoundDuty` / `MicFmt` enums; the friendly `SoundFormat_*` /
// `DutyCycle_*` aliases are macros the importer drops, so we re-expose them as
// Swift enums.
//===----------------------------------------------------------------------===//

public enum Sound {

    /// PCM sample format (`SoundFormat` / `SoundFmt`).
    public enum Format {
        case pcm8, pcm16, adpcm, psg
        @inline(__always) var c: SoundFormat {
            switch self {
            case .pcm8:  return SoundFmt_Pcm8
            case .pcm16: return SoundFmt_Pcm16
            case .adpcm: return SoundFmt_ImaAdpcm
            case .psg:   return SoundFmt_Psg
            }
        }
    }

    /// PSG square-wave duty cycle (`DutyCycle` / `SoundDuty`).
    public enum Duty {
        case d0, d12, d25, d37, d50, d62, d75, d87
        @inline(__always) var c: DutyCycle {
            switch self {
            case .d0:  return SoundDuty_0
            case .d12: return SoundDuty_12_5
            case .d25: return SoundDuty_25
            case .d37: return SoundDuty_37_5
            case .d50: return SoundDuty_50
            case .d62: return SoundDuty_62_5
            case .d75: return SoundDuty_75
            case .d87: return SoundDuty_87_5
            }
        }
    }

    @inline(__always) public static func enable()  { soundEnable() }
    @inline(__always) public static func disable() { soundDisable() }

    /// Play a PCM sample; returns the sound channel id (`soundPlaySample`).
    @discardableResult
    @inline(__always)
    public static func playSample(_ data: UnsafeRawPointer, format: Format, size: UInt32,
                                  frequency: UInt16, volume: UInt8 = 127, pan: UInt8 = 64,
                                  loop: Bool = false, loopPoint: UInt16 = 0) -> Int32 {
        soundPlaySample(data, format.c, size, frequency, volume, pan, loop, loopPoint)
    }

    /// Play a PSG square wave; returns the channel id (`soundPlayPSG`).
    @discardableResult
    @inline(__always)
    public static func playPSG(duty: Duty, frequency: UInt16, volume: UInt8 = 127, pan: UInt8 = 64) -> Int32 {
        soundPlayPSG(duty.c, frequency, volume, pan)
    }

    /// Play a noise channel; returns the channel id (`soundPlayNoise`).
    @discardableResult
    @inline(__always)
    public static func playNoise(frequency: UInt16, volume: UInt8 = 127, pan: UInt8 = 64) -> Int32 {
        soundPlayNoise(frequency, volume, pan)
    }

    @inline(__always) public static func pause(_ id: Int32)  { soundPause(id) }
    @inline(__always) public static func resume(_ id: Int32) { soundResume(id) }
    @inline(__always) public static func kill(_ id: Int32)   { soundKill(id) }
    @inline(__always) public static func setVolume(_ id: Int32, _ volume: UInt8) { soundSetVolume(id, volume) }
    @inline(__always) public static func setPan(_ id: Int32, _ pan: UInt8) { soundSetPan(id, pan) }
    @inline(__always) public static func setFrequency(_ id: Int32, _ freq: UInt16) { soundSetFreq(id, freq) }
    @inline(__always) public static func setWaveDuty(_ id: Int32, _ duty: Duty) { soundSetWaveDuty(id, duty.c) }
}
