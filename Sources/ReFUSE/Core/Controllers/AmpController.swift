// AmpController.swift
// Migrazione di amp_controller.ts

import Foundation

@MainActor
final class AmpController {
    private let state: AppState
    private let hid: MustangHIDManager

    init(state: AppState, hid: MustangHIDManager) {
        self.state = state
        self.hid = hid
    }

    // MARK: - Incoming HID Events

    func handleKnobChange(_ command: Command) -> Bool {
        guard case .knobChange(let dspType, _, let knobIndex, let value) = command,
              dspType == .amp else { return false }
        var amp = state.amp
        if knobIndex < amp.knobs.count {
            amp.knobs[knobIndex] = value
            state.updateAmpState(amp)
        }
        return true
    }

    func handleAmpUpdate(_ command: Command) {
        guard case .ampUpdate(let modelId, let cabinetId, let knobs) = command else { return }
        state.updateAmpState(AmpState(modelId: modelId, enabled: true, cabinetId: cabinetId, knobs: knobs))
    }

    // MARK: - Outgoing Commands

    func setAmpModelById(_ modelId: Int) async throws {
        guard let model = ampModelById(modelId) else {
            throw NSError(domain: "AmpController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown model 0x\(String(modelId, radix: 16))"])
        }
        _ = model
        let defaultBuffer = getModelDefault(modelId) ?? [UInt8](repeating: 0, count: 64)
        let newState = AmpState(
            modelId: modelId,
            enabled: true,
            cabinetId: Int(defaultBuffer[49]),
            knobs: Array(defaultBuffer[32..<64]).map { Int($0) }
        )
        state.updateAmpState(newState)
        try await sendAmpState(newState)
    }

    func setAmpKnob(index: Int, value: Int) async throws {
        var newState = state.amp
        guard index < newState.knobs.count else { return }
        newState.knobs[index] = value
        state.updateAmpState(newState)
        try await sendAmpState(newState)
    }

    func setCabinetById(_ id: Int) async throws {
        guard cabinetById(id) != nil else {
            throw NSError(domain: "AmpController", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unknown cabinet 0x\(String(id, radix: 16))"])
        }
        var newAmp = state.amp
        newAmp.cabinetId = id
        state.updateAmpState(newAmp)
        try await sendAmpState(newAmp)
    }

    // MARK: - Computed Properties

    func getAmpModel() -> ModelDef? { ampModelById(state.amp.modelId) }

    func getAmpKnobs() -> [KnobInfo] {
        guard let model = getAmpModel() else { return [] }
        let knobs = state.amp.knobs
        return model.knobs.enumerated().compactMap { (index, name) in
            guard !name.isEmpty else { return nil }
            return KnobInfo(name: name, value: index < knobs.count ? knobs[index] : 0, index: index)
        }
    }

    func getSettings() -> AmpSettingsView? {
        guard let model = getAmpModel() else { return nil }
        let k = state.amp.knobs
        let safeGet = { (i: Int) -> Int in i < k.count ? k[i] : 0 }
        return AmpSettingsView(
            model: model.name, modelId: model.id,
            volume: safeGet(0), gain: safeGet(1), gain2: safeGet(2),
            master: safeGet(3), treble: safeGet(4), mid: safeGet(5),
            bass: safeGet(6), presence: safeGet(7),
            depth: safeGet(9), bias: safeGet(10),
            noiseGate: safeGet(15), threshold: safeGet(16),
            cabinetId: state.amp.cabinetId,
            sag: safeGet(19), brightness: safeGet(20),
            knobs: getAmpKnobs()
        )
    }

    // MARK: - Private

    private func sendAmpState(_ s: AmpState) async throws {
        let seqId = hid.nextSequenceId()
        let packet = PacketBuilder.fromAmpState(s, sequenceId: seqId).build()
        try await hid.send(packet)
        let applyPacket = PacketBuilder.applyChange(dspType: .amp, sequenceId: hid.nextSequenceId()).build()
        try await hid.send(applyPacket)
    }
}

// MARK: - View Model

struct AmpSettingsView {
    let model: String
    let modelId: Int
    let volume, gain, gain2, master: Int
    let treble, mid, bass, presence: Int
    let depth, bias, noiseGate, threshold: Int
    let cabinetId: Int
    let sag, brightness: Int
    let knobs: [KnobInfo]
}
