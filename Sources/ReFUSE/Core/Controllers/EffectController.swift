// EffectController.swift
// Migrazione di effect_controller.ts

import Foundation

struct EffectSettingsView: Equatable {
    let slot: Int
    let type: DspType
    let model: String
    let modelId: Int
    let enabled: Bool
    let knobs: [KnobInfo]
}

@MainActor
final class EffectController {
    private let state: AppState
    private let hid: MustangHIDManager

    init(state: AppState, hid: MustangHIDManager) {
        self.state = state
        self.hid = hid
    }

    // MARK: - Incoming HID Events

    func handleKnobChange(_ command: Command) -> Bool {
        guard case .knobChange(_, let slot, let knobIndex, let value) = command,
              slot >= 0 && slot < 8,
              var effect = state.slots[slot] else { return false }
        if knobIndex < effect.knobs.count {
            effect.knobs[knobIndex] = value
            state.updateSlotState(slot: slot, state: effect)
        }
        return true
    }

    func handleEffectUpdate(_ command: Command) {
        guard case .effectUpdate(let slot, let dspType, let modelId, let enabled, let knobs) = command,
              slot >= 0 && slot < 8 else { return }

        // Singleton migration: clear same type from other slots
        for i in 0..<8 where i != slot {
            if let other = state.slots[i], other.type == dspType {
                state.clearSlot(i)
            }
        }

        if modelId == 0 {
            state.clearSlot(slot)
            return
        }

        state.updateSlotState(slot: slot, state: EffectState(
            slot: slot, type: dspType, modelId: modelId, enabled: enabled, knobs: knobs
        ))
    }

    func handleBypassState(_ command: Command) {
        guard case .bypassState(let slot, let enabled) = command,
              slot >= 0 && slot < 8 else { return }
        state.setEffectBypass(slot: slot, enabled: enabled)
    }

    // MARK: - Outgoing Commands

    func setEffectById(slot: Int, modelId: Int) async throws {
        guard let model = effectModelById(modelId) else {
            throw NSError(domain: "EffectController", code: -1)
        }
        guard slot >= 0 && slot <= 7 else {
            throw NSError(domain: "EffectController", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid slot \(slot)"])
        }

        // Remove same-type effect from other slots
        for i in 0..<8 where i != slot {
            if let other = state.slots[i], other.type == model.type {
                try await clearEffect(i)
            }
        }

        let buffer = getModelDefault(modelId) ?? [UInt8](repeating: 0, count: 64)
        let newState = EffectState(
            slot: slot, type: model.type, modelId: modelId, enabled: true,
            knobs: Array(buffer[32..<64]).map { Int($0) }
        )
        state.updateSlotState(slot: slot, state: newState)
        try await sendEffectState(newState)
    }

    func setEffectEnabled(slot: Int, enabled: Bool) async throws {
        guard let effect = state.slots[slot] else { return }
        state.setEffectBypass(slot: slot, enabled: enabled)
        let packet = PacketBuilder.bypass(slot: slot, enabled: enabled, dspType: effect.type).build()
        try await hid.send(packet)
    }

    func setEffectKnob(slot: Int, index: Int, value: Int) async throws {
        guard var effect = state.slots[slot] else {
            throw NSError(domain: "EffectController", code: -3, userInfo: [NSLocalizedDescriptionKey: "No effect in slot \(slot)"])
        }
        effect.knobs[index] = value
        state.updateSlotState(slot: slot, state: effect)
        try await sendEffectState(effect)
    }

    func clearEffect(_ slot: Int) async throws {
        guard slot >= 0 && slot <= 7 else { return }
        let type = state.slots[slot]?.type ?? .stomp
        state.clearSlot(slot)
        try await sendClearPacket(slot: slot, type: type)
    }

    func moveEffect(fromSlot: Int, toSlot: Int) async throws {
        guard fromSlot >= 0 && fromSlot <= 7 && toSlot >= 0 && toSlot <= 7,
              fromSlot != toSlot else { return }

        var slots = state.slots
        let fromGroup = fromSlot < 4 ? "pre" : "post"
        let toGroup = toSlot < 4 ? "pre" : "post"

        if fromGroup == toGroup {
            let groupStart = fromGroup == "pre" ? 0 : 4
            var groupSlots = Array(slots[groupStart..<groupStart+4])
            let relFrom = fromSlot - groupStart
            let relTo   = toSlot   - groupStart
            let moved = groupSlots.remove(at: relFrom)
            groupSlots.insert(moved, at: relTo)
            for i in 0..<4 { slots[groupStart + i] = groupSlots[i] }
        } else {
            let srcStart = fromGroup == "pre" ? 0 : 4
            var srcSlots = Array(slots[srcStart..<srcStart+4])
            let moved = srcSlots.remove(at: fromSlot - srcStart)
            srcSlots.append(nil)

            let tgtStart = toGroup == "pre" ? 0 : 4
            var tgtSlots = Array(slots[tgtStart..<tgtStart+4])
            tgtSlots.insert(moved, at: toSlot - tgtStart)
            tgtSlots.removeLast()

            for i in 0..<4 {
                slots[srcStart + i] = srcSlots[i]
                slots[tgtStart + i] = tgtSlots[i]
            }
        }

        for i in 0..<8 {
            let old = state.slots[i]
            var new = slots[i]
            if new != old || (new != nil && new!.slot != i) {
                if var effect = new {
                    effect.slot = i
                    state.updateSlotState(slot: i, state: effect)
                    try await sendEffectState(effect)
                } else if old != nil {
                    state.updateSlotState(slot: i, state: nil)
                    try await sendClearPacket(slot: i, type: .stomp)
                }
            }
        }
    }

    // MARK: - Computed

    func getSettings(slot: Int) -> EffectSettingsView? {
        guard let effect = state.slots[slot] else { return nil }
        let model = effectModelById(effect.modelId)
        let modelName = model?.name ?? "Unknown (0x\(String(effect.modelId, radix: 16)))"
        let knobs: [KnobInfo]
        if let m = model {
            knobs = m.knobs.enumerated().compactMap { (i, name) in
                guard !name.isEmpty else { return nil }
                return KnobInfo(name: name, value: i < effect.knobs.count ? effect.knobs[i] : 0, index: i)
            }
        } else { knobs = [] }
        return EffectSettingsView(slot: slot, type: effect.type, model: modelName, modelId: effect.modelId, enabled: effect.enabled, knobs: knobs)
    }

    // MARK: - Private

    private func sendEffectState(_ s: EffectState) async throws {
        let seq = hid.nextSequenceId()
        try await hid.send(PacketBuilder.fromEffectState(s, sequenceId: seq).build())
        try await hid.send(PacketBuilder.applyChange(dspType: s.type, sequenceId: hid.nextSequenceId()).build())
    }

    private func sendClearPacket(slot: Int, type: DspType) async throws {
        let seq = hid.nextSequenceId()
        let builder = PacketBuilder.dspWrite(type: type, sequenceId: seq)
        builder.setByte(18, UInt8(slot))
        builder.setByte(22, 1)
        try await hid.send(builder.build())
        try await hid.send(PacketBuilder.applyChange(dspType: type, sequenceId: hid.nextSequenceId()).build())
    }
}
