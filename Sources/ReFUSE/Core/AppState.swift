// AppState.swift
// Migrazione di store.ts — stato globale reattivo con @Observable (macOS 14+)

import Foundation
import Observation

// MARK: - State Models

struct PresetMetadata: Equatable {
    let slot: Int
    let name: String
}

struct KnobInfo: Equatable {
    let name: String
    let value: Int
    let index: Int
}

struct AmpState: Equatable {
    var modelId: Int
    var enabled: Bool
    var cabinetId: Int
    var knobs: [Int] // 32 values (indices 0..31 = bytes 32..63)
}

struct EffectState: Equatable {
    var slot: Int
    var type: DspType
    var modelId: Int
    var enabled: Bool
    var knobs: [Int]
}

// MARK: - AppState

@Observable
@MainActor
final class AppState {
    var amp: AmpState = AmpState(
        modelId: 0,
        enabled: true,
        cabinetId: 0,
        knobs: [Int](repeating: 0, count: 32)
    )

    var slots: [EffectState?] = [EffectState?](repeating: nil, count: 8)
    var currentPresetSlot: Int? = nil
    var presets: [Int: PresetMetadata] = [:]
    var connected: Bool = false
    var refreshing: Bool = false

    // MARK: - Mutators (mirror di store.ts)

    func setConnected(_ value: Bool) {
        connected = value
    }

    func setRefreshing(_ value: Bool) {
        refreshing = value
    }

    func setPresetActive(slot: Int, name: String) {
        guard !name.isEmpty else { return }
        presets[slot] = PresetMetadata(slot: slot, name: name)
        if !refreshing || currentPresetSlot == nil {
            currentPresetSlot = slot
        }
    }

    func setPresetMetadata(slot: Int, name: String) {
        guard !name.isEmpty else { return }
        presets[slot] = PresetMetadata(slot: slot, name: name)
    }

    func updateAmpState(_ state: AmpState) {
        amp = state
    }

    func updateSlotState(slot: Int, state: EffectState?) {
        guard slot >= 0 && slot < 8 else { return }
        slots[slot] = state
    }

    func setEffectBypass(slot: Int, enabled: Bool) {
        guard slot >= 0 && slot < 8, var effect = slots[slot] else { return }
        effect.enabled = enabled
        slots[slot] = effect
    }

    func clearSlot(_ slot: Int) {
        guard slot >= 0 && slot < 8 else { return }
        slots[slot] = nil
    }
}
