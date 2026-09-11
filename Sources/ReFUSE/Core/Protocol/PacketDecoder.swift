// PacketDecoder.swift
// Migrazione 1:1 di protocol_decoder.ts

import Foundation

// MARK: - Command Types

enum Command {
    case knobChange(dspType: DspType, slot: Int, knobIndex: Int, value: Int)
    case ampUpdate(modelId: Int, cabinetId: Int, knobs: [Int])
    case effectUpdate(slot: Int, dspType: DspType, modelId: Int, enabled: Bool, knobs: [Int])
    case presetInfo(slot: Int, name: String)
    case presetChange(slot: Int, name: String)
    case bypassState(slot: Int, enabled: Bool)
    case unknown(raw: [UInt8])
}

// MARK: - Decoder

struct PacketDecoder {
    static func decode(_ data: [UInt8]) -> Command {
        guard data.count >= PACKET_SIZE else {
            return .unknown(raw: data)
        }

        let command = data[OFFSETS.COMMAND]
        let subCommand = data[OFFSETS.SUB_COMMAND]

        // 1. Live Knob Change (type byte 0x05..0x09)
        if let dspType = DspType(rawValue: command), subCommand == 0x00 {
            let slot = Int(data[OFFSETS.LIVE_SLOT_INDEX])
            let paramIndex = Int(data[OFFSETS.LIVE_KNOB_INDEX])
            let paramValue = Int(data[OFFSETS.LIVE_KNOB_VALUE])
            return .knobChange(dspType: dspType, slot: slot, knobIndex: paramIndex, value: paramValue)
        }

        // 2. Data Packet (0x1c 0x01)
        if command == OPCODES.DATA_PACKET && subCommand == OPCODES.DATA_READ {
            let type = data[OFFSETS.TYPE]

            // Preset Info / Change
            if type == 0x04 || type == 0x00 {
                if data[3] != 0x00 { return .unknown(raw: data) }
                let slot = Int(data[OFFSETS.PRESET_SLOT])
                let nameBytes = Array(data[OFFSETS.PRESET_NAME..<min(OFFSETS.PRESET_NAME + 32, data.count)])
                let name = parseName(nameBytes)
                if type == 0x00 {
                    return .presetChange(slot: slot, name: name)
                } else {
                    return .presetInfo(slot: slot, name: name)
                }
            }

            // Amp Update
            if type == DspType.amp.rawValue {
                if data[3] != 0x00 { return .unknown(raw: data) }
                let modelId = (Int(data[OFFSETS.MODEL_ID_MSB]) << 8) | Int(data[OFFSETS.MODEL_ID_LSB])
                let cabinetId = Int(data[OFFSETS.CABINET_ID])
                let knobs = Array(data[OFFSETS.KNOB_START..<OFFSETS.KNOB_END]).map { Int($0) }
                return .ampUpdate(modelId: modelId, cabinetId: cabinetId, knobs: knobs)
            }

            // Effect Update
            if let dspType = DspType(rawValue: type),
               dspType != .amp,
               data[3] == 0x00 {
                let slot = Int(data[OFFSETS.SLOT_INDEX])
                let modelId = (Int(data[OFFSETS.MODEL_ID_MSB]) << 8) | Int(data[OFFSETS.MODEL_ID_LSB])
                let bypassed = data[OFFSETS.BYPASS] == VALUES.BYPASSED
                let knobs = Array(data[OFFSETS.KNOB_START..<OFFSETS.KNOB_END]).map { Int($0) }
                return .effectUpdate(slot: slot, dspType: dspType, modelId: modelId, enabled: !bypassed, knobs: knobs)
            }
        }

        // 3. Bypass Response (0x19 0xc3)
        if command == OPCODES.BYPASS_PACKET && subCommand == OPCODES.BYPASS_RESPONSE {
            let slot = Int(data[4])
            let enabled = data[3] == VALUES.ENABLED
            return .bypassState(slot: slot, enabled: enabled)
        }

        return .unknown(raw: data)
    }

    private static func parseName(_ bytes: [UInt8]) -> String {
        let terminated = bytes.prefix(while: { $0 != 0 })
        return String(bytes: terminated, encoding: .utf8) ?? ""
    }
}
