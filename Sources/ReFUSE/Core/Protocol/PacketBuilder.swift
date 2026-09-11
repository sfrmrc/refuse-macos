// PacketBuilder.swift
// Migrazione 1:1 di packet_builder.ts

import Foundation

// MARK: - PacketBuilder

final class PacketBuilder {
    private var buffer: [UInt8]

    init() {
        buffer = [UInt8](repeating: 0, count: PACKET_SIZE)
    }

    @discardableResult
    func setCommand(_ command: UInt8) -> PacketBuilder {
        buffer[0] = command; return self
    }

    @discardableResult
    func setSubCommand(_ sub: UInt8) -> PacketBuilder {
        buffer[1] = sub; return self
    }

    @discardableResult
    func setType(_ type: UInt8) -> PacketBuilder {
        buffer[2] = type; return self
    }

    @discardableResult
    func setByte(_ index: Int, _ value: UInt8) -> PacketBuilder {
        if index >= 0 && index < PACKET_SIZE { buffer[index] = value }
        return self
    }

    @discardableResult
    func addBytes(startIndex: Int, values: [UInt8]) -> PacketBuilder {
        for (i, v) in values.enumerated() {
            let idx = startIndex + i
            if idx < PACKET_SIZE { buffer[idx] = v }
        }
        return self
    }

    @discardableResult
    func setSequenceId(_ id: UInt8) -> PacketBuilder {
        buffer[6] = id
        buffer[7] = 0x01 // Always 0x01 for sequence validation
        return self
    }

    func build() -> [UInt8] { buffer }

    // MARK: - Static Factories

    static func dspWrite(type: DspType, sequenceId: UInt8) -> PacketBuilder {
        PacketBuilder()
            .setCommand(OPCODES.DATA_PACKET)
            .setSubCommand(OPCODES.DATA_WRITE)
            .setType(type.rawValue)
            .setSequenceId(sequenceId)
    }

    static func applyChange(dspType: DspType, sequenceId: UInt8) -> PacketBuilder {
        let builder = PacketBuilder()
            .setCommand(OPCODES.DATA_PACKET)
            .setSubCommand(OPCODES.DATA_WRITE)
            .setType(0x00)
            .setSequenceId(sequenceId)
        builder.setByte(4, dspType == .mod ? 0x01 : 0x02)
        return builder
    }

    static func bypass(slot: Int, enabled: Bool, dspType: DspType) -> PacketBuilder {
        let family = UInt8(dspType.rawValue) - 3
        return PacketBuilder()
            .setCommand(OPCODES.BYPASS_PACKET)
            .setSubCommand(OPCODES.BYPASS_SET)
            .setByte(2, family)
            .setByte(3, enabled ? VALUES.ENABLED : VALUES.BYPASSED)
            .setByte(4, UInt8(slot))
    }

    static func savePreset(slot: Int, name: String) -> PacketBuilder {
        let builder = PacketBuilder()
            .setCommand(OPCODES.DATA_PACKET)
            .setSubCommand(OPCODES.DATA_READ)
            .setType(0x03)
            .setByte(3, 0x00)
            .setByte(OFFSETS.PRESET_SLOT, UInt8(slot))
            .setByte(5, 0x00)
            .setByte(6, 0x01)
            .setByte(7, 0x01)
        let nameBytes = Array(name.prefix(32).utf8)
        builder.addBytes(startIndex: OFFSETS.PRESET_NAME, values: nameBytes)
        return builder
    }

    static func loadPreset(slot: Int) -> PacketBuilder {
        PacketBuilder()
            .setCommand(OPCODES.DATA_PACKET)
            .setSubCommand(OPCODES.DATA_READ)
            .setType(0x01)
            .setByte(3, 0x00)
            .setByte(OFFSETS.PRESET_SLOT, UInt8(slot))
            .setByte(5, 0x00)
            .setByte(6, 0x01)
    }

    static func fromAmpState(_ state: AmpState, sequenceId: UInt8) -> PacketBuilder {
        let builder = PacketBuilder.dspWrite(type: .amp, sequenceId: sequenceId)
        builder.setByte(OFFSETS.MODEL_ID_MSB, UInt8((state.modelId >> 8) & 0xff))
        builder.setByte(OFFSETS.MODEL_ID_LSB, UInt8(state.modelId & 0xff))
        builder.setByte(OFFSETS.CABINET_ID, UInt8(state.cabinetId))
        builder.addBytes(startIndex: OFFSETS.KNOB_START, values: state.knobs.map { UInt8($0 & 0xff) })
        return builder
    }

    static func fromEffectState(_ state: EffectState, sequenceId: UInt8) -> PacketBuilder {
        let builder = PacketBuilder.dspWrite(type: state.type, sequenceId: sequenceId)
        builder.setByte(OFFSETS.MODEL_ID_MSB, UInt8((state.modelId >> 8) & 0xff))
        builder.setByte(OFFSETS.MODEL_ID_LSB, UInt8(state.modelId & 0xff))
        builder.setByte(OFFSETS.SLOT_INDEX, UInt8(state.slot))
        builder.setByte(OFFSETS.BYPASS, state.enabled ? VALUES.ENABLED : VALUES.BYPASSED)
        builder.addBytes(startIndex: OFFSETS.KNOB_START, values: state.knobs.map { UInt8($0 & 0xff) })
        return builder
    }

    static func handshake1() -> [UInt8] { [OPCODES.HANDSHAKE_1] }
    static func handshake2() -> [UInt8] { [OPCODES.HANDSHAKE_2_BYTE1, OPCODES.HANDSHAKE_2_BYTE2] }
    static func requestState() -> [UInt8] { [OPCODES.REQUEST_STATE, OPCODES.REQUEST_STATE_BYTE2] }
    static func requestBypassStates() -> [UInt8] { [OPCODES.REQUEST_BYPASS, OPCODES.REQUEST_BYPASS_BYTE2] }
}
