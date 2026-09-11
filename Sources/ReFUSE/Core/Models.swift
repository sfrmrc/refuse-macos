// Models.swift
// Migrazione 1:1 di models.ts

import Foundation

// MARK: - DSP Type

enum DspType: UInt8 {
    case amp    = 0x05
    case stomp  = 0x06
    case mod    = 0x07
    case delay  = 0x08
    case reverb = 0x09
}

// MARK: - Model Definitions

struct ModelDef {
    let id: Int
    let name: String
    let type: DspType
    let knobs: [String] // nome knob, stringa vuota = nascosto
}

struct CabinetDef {
    let id: Int
    let name: String
}

private func m(_ id: Int, _ name: String, _ type: DspType, _ knobs: [String]) -> ModelDef {
    ModelDef(id: id, name: name, type: type, knobs: knobs)
}

// MARK: - Amp Models

let AMP_MODELS: [String: ModelDef] = [
    // Standard V1
    "F57_DELUXE":    m(0x6700, "'57 Deluxe",         .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "F59_BASSMAN":   m(0x6400, "'59 Bassman",         .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "F57_CHAMP":     m(0x7c00, "'57 Champ",           .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "F65_DELUXE":    m(0x5300, "'65 Deluxe Reverb",   .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "F65_PRINCETON": m(0x6a00, "'65 Princeton",        .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "F65_TWIN":      m(0x7500, "'65 Twin Reverb",      .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "SUPER_SONIC":   m(0x7200, "Super-Sonic",          .amp, ["Vol","Gain","Gain2","Master","Treb","Mid","Bass","Pres"]),
    "BRIT_60S":      m(0x6100, "British '60s",         .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "BRIT_70S":      m(0x7900, "British '70s",         .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "BRIT_80S":      m(0x5e00, "British '80s",         .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "US_90S":        m(0x5d00, "American '90s",        .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "METAL_2000":    m(0x6d00, "Metal 2000",           .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    // V2 / Hidden
    "STUDIO_PREAMP": m(0xf100, "Studio Preamp",        .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "F57_TWIN":      m(0xf600, "'57 Twin",             .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "THRIFT_60S":    m(0xf900, "'60s Thrift",          .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "BRIT_WATTS":    m(0xff00, "British Watts",         .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
    "BRIT_COLOUR":   m(0xfc00, "British Colour",        .amp, ["Vol","Gain","","Master","Treb","Mid","Bass","Pres"]),
]

// MARK: - Effect Models

let EFFECT_MODELS: [String: ModelDef] = [
    // Stomps
    "OVERDRIVE":       m(0x3c00, "Overdrive",          .stomp,  ["Level","Gain","Low","Mid","High",""]),
    "WAH":             m(0x4900, "Fixed Wah",           .stomp,  ["Level","Freq","Min","Max","Q",""]),
    "TOUCH_WAH":       m(0x4a00, "Touch Wah",           .stomp,  ["Level","Sens","Min","Max","Q",""]),
    "FUZZ":            m(0x1a00, "Fuzz",                .stomp,  ["Level","Gain","Octave","Low","High",""]),
    "FUZZ_TOUCH_WAH":  m(0x1c00, "Fuzz Touch Wah",     .stomp,  ["Level","Gain","Sens","Octave","Peak",""]),
    "SIMPLE_COMP":     m(0x8800, "Simple Comp",         .stomp,  ["Type","","","","",""]),
    "COMPRESSOR":      m(0x0700, "Compressor",          .stomp,  ["Level","Thresh","Ratio","Attack","Release",""]),
    "RANGER_BOOST":    m(0x0301, "Ranger Boost",        .stomp,  ["Level","Gain","Tone","","",""]),
    "GREEN_BOX":       m(0xba00, "Green Box",           .stomp,  ["Level","Gain","Tone","Blend","",""]),
    "ORANGE_BOX":      m(0x0101, "Orange Box",          .stomp,  ["Level","Gain","Tone","","",""]),
    "BLACK_BOX":       m(0x1101, "Black Box",           .stomp,  ["Level","Gain","Tone","","",""]),
    "BIG_FUZZ":        m(0x0f01, "Big Fuzz",            .stomp,  ["Level","Tone","Sustain","","",""]),
    // Mod
    "SINE_CHORUS":     m(0x1200, "Sine Chorus",         .mod,    ["Level","Rate","Depth","Avg Dly","LR Phase",""]),
    "TRIANGLE_CHORUS": m(0x1300, "Triangle Chorus",     .mod,    ["Level","Rate","Depth","Avg Dly","LR Phase",""]),
    "SINE_FLANGER":    m(0x1800, "Sine Flanger",        .mod,    ["Level","Rate","Depth","Fdbk","LR Phase",""]),
    "TRIANGLE_FLANGER":m(0x1900, "Triangle Flanger",    .mod,    ["Level","Rate","Depth","Fdbk","LR Phase",""]),
    "VIBRATONE":       m(0x2d00, "Vibratone",           .mod,    ["Level","Rotor","Depth","Fdbk","LR Phase",""]),
    "VINTAGE_TREMOLO": m(0x4000, "Vintage Tremolo",     .mod,    ["Level","Rate","Duty","Attack","Release",""]),
    "SINE_TREMOLO":    m(0x4100, "Sine Tremolo",        .mod,    ["Level","Rate","Duty","LFO Clip","Tri Shape",""]),
    "RING_MODULATOR":  m(0x2200, "Ring Modulator",      .mod,    ["Level","Freq","Depth","Shape","Phase",""]),
    "STEP_FILTER":     m(0x2900, "Step Filter",         .mod,    ["Level","Rate","Res","Min Freq","Max Freq",""]),
    "PHASER":          m(0x4f00, "Phaser",              .mod,    ["Level","Rate","Depth","Fdbk","Shape",""]),
    "PITCH_SHIFTER":   m(0x1f00, "Pitch Shifter",       .mod,    ["Level","Pitch","Detune","Fdbk","PreDly",""]),
    // Delay
    "MONO_DELAY":         m(0x1600, "Mono Delay",           .delay, ["Level","Time","Fdbk","Bright","Atten",""]),
    "MONO_ECHO_FILTER":   m(0x4300, "Mono Echo Filter",     .delay, ["Level","Time","Fdbk","Freq","Res","Input"]),
    "STEREO_ECHO_FILTER": m(0x4800, "Stereo Echo Filter",   .delay, ["Level","Time","Fdbk","Freq","Res","Input"]),
    "TAPE_DELAY":         m(0x2b00, "Tape Delay",           .delay, ["Level","Time","Fdbk","Flutter","Bright","Stereo"]),
    "STEREO_TAPE_DELAY":  m(0x2a00, "Stereo Tape Delay",    .delay, ["Level","Time","Fdbk","Flutter","Sep","Bright"]),
    "DUCKING_DELAY":      m(0x1500, "Ducking Delay",        .delay, ["Level","Time","Fdbk","Release","Thresh",""]),
    "REVERSE_DELAY":      m(0x4600, "Reverse Delay",        .delay, ["Level","Time","Fdbk","Bright","Atten",""]),
    "MULTITAP_DELAY":     m(0x4400, "Multitap Delay",       .delay, ["Level","Time","Fdbk","Bright","Atten",""]),
    "PING_PONG_DELAY":    m(0x4500, "Ping Pong Delay",      .delay, ["Level","Time","Fdbk","Bright","Atten",""]),
    // Reverb
    "SMALL_HALL":  m(0x2400, "Small Hall",   .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "LARGE_HALL":  m(0x3a00, "Large Hall",   .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "SMALL_ROOM":  m(0x2600, "Small Room",   .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "LARGE_ROOM":  m(0x3b00, "Large Room",   .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "SMALL_PLATE": m(0x4e00, "Small Plate",  .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "LARGE_PLATE": m(0x4b00, "Large Plate",  .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "AMBIENT":     m(0x4c00, "Ambient",      .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "ARENA":       m(0x4d00, "Arena",        .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "SPRING_63":   m(0x2100, "'63 Spring",   .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
    "SPRING_65":   m(0x0b00, "'65 Spring",   .reverb, ["Level","Decay","Dwell","Diff","Tone",""]),
]

// MARK: - Cabinet Models

let CABINET_MODELS: [CabinetDef] = [
    CabinetDef(id: 0x00, name: "Off"),
    CabinetDef(id: 0x01, name: "1x12 '57 Deluxe"),
    CabinetDef(id: 0x02, name: "4x10 '59 Bassman"),
    CabinetDef(id: 0x03, name: "1x8 '57 Champ"),
    CabinetDef(id: 0x04, name: "1x12 '65 Deluxe"),
    CabinetDef(id: 0x05, name: "1x10 '65 Princeton"),
    CabinetDef(id: 0x06, name: "4x12 Metal 2000"),
    CabinetDef(id: 0x07, name: "2x12 British '60s"),
    CabinetDef(id: 0x08, name: "4x12 British '70s"),
    CabinetDef(id: 0x09, name: "2x12 '65 Twin"),
    CabinetDef(id: 0x0a, name: "4x12 British '80s"),
    CabinetDef(id: 0x0b, name: "2x12 Super-Sonic"),
    CabinetDef(id: 0x0c, name: "1x12 Super-Sonic"),
    CabinetDef(id: 0x0d, name: "2x12 '57 Twin"),
    CabinetDef(id: 0x0e, name: "2x12 '60s Thrift"),
    CabinetDef(id: 0x0f, name: "4x12 British Watts"),
    CabinetDef(id: 0x10, name: "4x12 British Colour"),
]

// MARK: - Convenience Lookups

extension Collection where Element == (key: String, value: ModelDef) {
    func findById(_ id: Int) -> ModelDef? {
        first(where: { $0.value.id == id })?.value
    }
}

func ampModelById(_ id: Int) -> ModelDef? {
    AMP_MODELS.values.first(where: { $0.id == id })
}

func effectModelById(_ id: Int) -> ModelDef? {
    EFFECT_MODELS.values.first(where: { $0.id == id })
}

func cabinetById(_ id: Int) -> CabinetDef? {
    CABINET_MODELS.first(where: { $0.id == id })
}
