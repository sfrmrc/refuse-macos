// PresetController.swift
// Migrazione di preset_controller.ts

import Foundation

@MainActor
final class PresetController {
    private let state: AppState
    private let hid: MustangHIDManager

    var onLoad: ((Int, String) -> Void)?

    init(state: AppState, hid: MustangHIDManager) {
        self.state = state
        self.hid = hid
    }

    // MARK: - Incoming HID Events

    func handlePresetChange(_ command: Command) {
        guard case .presetChange(let slot, let name) = command else { return }
        state.setPresetActive(slot: slot, name: name)
        onLoad?(slot, name)
    }

    func handlePresetInfo(_ command: Command) {
        guard case .presetInfo(let slot, let name) = command else { return }
        state.setPresetMetadata(slot: slot, name: name)
    }

    // MARK: - Outgoing Commands

    func loadPreset(slot: Int) async throws {
        let packet = PacketBuilder.loadPreset(slot: slot).build()
        try await hid.send(packet)
    }

    func savePreset(slot: Int, name: String) async throws {
        let packet = PacketBuilder.savePreset(slot: slot, name: name).build()
        try await hid.send(packet)
        state.setPresetActive(slot: slot, name: name)
        onLoad?(slot, name)
    }

    // MARK: - XML Import (Fender FUSE preset format)

    func loadXml(_ xmlString: String) async throws {
        guard let data = xmlString.data(using: .utf8) else { return }
        let parser = FuseXMLParser(data: data)
        let presetData = try parser.parse()

        // Build and send amp packet
        if let ampData = presetData.ampPacket {
            try await hid.send(ampData)
            try await hid.send(PacketBuilder.applyChange(dspType: .amp, sequenceId: hid.nextSequenceId()).build())
        }

        // Build and send effect packets
        for effectData in presetData.effectPackets {
            try await hid.send(effectData.packet)
            try await hid.send(PacketBuilder.applyChange(dspType: effectData.type, sequenceId: hid.nextSequenceId()).build())
        }

        let currentSlot = state.currentPresetSlot ?? 0
        onLoad?(currentSlot, "Imported Preset")
    }

    // MARK: - Queries

    func getPresets() -> [PresetMetadata] {
        state.presets.values.sorted { $0.slot < $1.slot }
    }
}

// MARK: - Minimal FUSE XML Parser

private struct ParsedPreset {
    var ampPacket: [UInt8]?
    var effectPackets: [(packet: [UInt8], type: DspType)] = []
}

private final class FuseXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var result = ParsedPreset()
    private var parseError: Error?
    
    // Internal state
    private var currentModuleType: DspType? = nil
    private var currentModuleID: Int = 0
    private var currentModulePos: Int = 0
    private var currentModuleBypass: Int = 0
    private var currentKnobs: [Int: Int] = [:]

    init(data: Data) { self.data = data }

    func parse() throws -> ParsedPreset {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        if let err = parseError { throw err }
        return result
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String] = [:]) {
        switch elementName {
        case "Amplifier":
            currentModuleType = .amp
        case "FXStompbox", "FX Stompbox":
            currentModuleType = .stomp
        case "FXModulation", "FX Modulation":
            currentModuleType = .mod
        case "FXDelay", "FX Delay":
            currentModuleType = .delay
        case "FXReverb", "FX Reverb":
            currentModuleType = .reverb
        case "Module":
            if currentModuleType != nil {
                currentModuleID = Int(attributes["ID"] ?? "0") ?? 0
                currentModulePos = Int(attributes["POS"] ?? "0") ?? 0
                currentModuleBypass = Int(attributes["BypassState"] ?? "0") ?? 0
                currentKnobs.removeAll()
            }
        case "Param":
            if currentModuleType != nil {
                let controlIndex = Int(attributes["ControlIndex"] ?? "0") ?? 0
                currentKnobs[controlIndex] = 0 // Will read value in foundCharacters, but typically FUSE sets it in the element text
                // Store the index to populate when text arrives
                lastParamIndex = controlIndex
            }
        default:
            break
        }
    }
    
    private var lastParamIndex: Int?
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let idx = lastParamIndex, let val16 = Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            currentKnobs[idx] = val16 >> 8
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "Param" {
            lastParamIndex = nil
        } else if elementName == "Module", let type = currentModuleType {
            if currentModuleID != 0, let modelId = resolveId(fuseId: currentModuleID, type: type) {
                var buffer = [UInt8](repeating: 0, count: 64)
                buffer[16] = UInt8((modelId >> 8) & 0xff)
                buffer[17] = UInt8(modelId & 0xff)
                buffer[18] = UInt8(currentModulePos)
                buffer[22] = UInt8(currentModuleBypass)
                
                for (idx, val8) in currentKnobs {
                    if 32 + idx < 64 {
                        buffer[32 + idx] = UInt8(val8)
                    }
                }
                
                let builder = PacketBuilder.dspWrite(type: type, sequenceId: 0) // sequenceId is overwritten by HID manager on send
                builder.addBytes(startIndex: 16, values: Array(buffer[16..<64]))
                let packet = builder.build()
                
                if type == .amp {
                    result.ampPacket = packet
                } else {
                    result.effectPackets.append((packet: packet, type: type))
                }
            }
        } else if ["Amplifier", "FXStompbox", "FX Stompbox", "FXModulation", "FX Modulation", "FXDelay", "FX Delay", "FXReverb", "FX Reverb"].contains(elementName) {
            currentModuleType = nil
        }
    }
    
    private let idMap: [Int: Int] = [
        0: 0x6700, 1: 0x6400, 2: 0x7c00, 3: 0x5300, 4: 0x6a00, 5: 0x7500,
        6: 0x7200, 7: 0x6100, 8: 0x7900, 9: 0x5e00, 10: 0x5d00, 11: 0x6d00,
        100: 0xf100, 101: 0xf600, 102: 0xf900, 103: 0xff00, 104: 0xfc00,
        105: 0x5300, 106: 0x6a00, 107: 0x7500, 108: 0x7200,
        19: 0x3c00, 20: 0x4900, 21: 0x4a00, 22: 0x1a00, 23: 0x1c00, 24: 0x0700, 25: 0x8800,
        109: 0x0301, 110: 0xba00, 111: 0x1001, 112: 0x1101, 113: 0x0f01,
        26: 0x1200, 27: 0x1300, 28: 0x1800, 29: 0x1900, 30: 0x2d00, 31: 0x4000,
        32: 0x4100, 33: 0x2200, 34: 0x2900, 35: 0x4f00, 36: 0x1f00,
        37: 0x1600, 38: 0x2b00, 39: 0x1500, 40: 0x4600, 41: 0x4800,
        42: 0x2400, 43: 0x3a00, 44: 0x2600, 45: 0x3b00, 46: 0x4e00, 47: 0x4b00,
        48: 0x4c00, 49: 0x4d00, 50: 0x2100, 51: 0x0b00
    ]

    private func resolveId(fuseId: Int, type: DspType) -> Int? {
        if let mapped = idMap[fuseId] { return mapped }
        
        let high = fuseId << 8
        let repo: [String: ModelDef] = type == .amp ? AMP_MODELS : EFFECT_MODELS
        if repo.values.contains(where: { $0.id == high }) { return high }
        
        let swapped = ((fuseId & 0xff) << 8) | ((fuseId >> 8) & 0xff)
        if repo.values.contains(where: { $0.id == swapped }) { return swapped }
        
        return nil
    }
}
