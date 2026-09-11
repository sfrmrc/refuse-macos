// FuseAPI.swift
// Migrazione di index.ts — facade principale dell'API
// Equivalente di FuseAPI + connect/disconnect + monitoring loop

import Foundation

@Observable
@MainActor
final class FuseAPI {
    let state: AppState
    let hid: MustangHIDManager

    let amp: AmpController
    let effects: EffectController
    let presets: PresetController

    private var monitoringId: UUID?
    private var isRefreshing = false

    var isConnected: Bool { hid.isConnected }

    init() {
        let state = AppState()
        let hid = MustangHIDManager()
        self.state = state
        self.hid = hid
        self.amp = AmpController(state: state, hid: hid)
        self.effects = EffectController(state: state, hid: hid)
        self.presets = PresetController(state: state, hid: hid)
    }

    // MARK: - Connect

    func connect() async -> Bool {
        let connected = await hid.connect()
        guard connected else { return false }

        state.setConnected(true)
        state.setRefreshing(true)
        isRefreshing = true
        startMonitoring()

        defer {
            isRefreshing = false
            state.setRefreshing(false)
        }

        // Request full state dump
        try? await hid.send(PacketBuilder.requestState())

        // Request bypass states for all 8 slots
        await refreshBypassStates()

        // Padding — ensures dump packets are fully processed
        try? await Task.sleep(nanoseconds: 500_000_000)

        return true
    }

    // MARK: - Disconnect

    func disconnect() async {
        if let id = monitoringId {
            hid.removeListener(id)
            monitoringId = nil
        }
        await hid.disconnect()
        state.setConnected(false)
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        guard monitoringId == nil else { return }

        monitoringId = hid.addListener { [weak self] data in
            guard let self else { return }
            Task { @MainActor in
                self.handleIncomingPacket(data)
            }
        }

        // Subscribe to preset load events (equivalent di onLoad in index.ts)
        presets.onLoad = { [weak self] slot, name in
            // No auto-refresh needed — amp sends PRESET_INFO/AMP_UPDATE/EFFECT_UPDATE automatically
            // (avoids the infinite loop described in the original code)
            _ = slot; _ = name
        }
    }

    private func handleIncomingPacket(_ data: [UInt8]) {
        let command = PacketDecoder.decode(data)
        switch command {
        case .knobChange:
            if !amp.handleKnobChange(command) {
                _ = effects.handleKnobChange(command)
            }
        case .ampUpdate:
            amp.handleAmpUpdate(command)
        case .effectUpdate:
            effects.handleEffectUpdate(command)
        case .bypassState:
            effects.handleBypassState(command)
        case .presetChange:
            presets.handlePresetChange(command)
        case .presetInfo:
            presets.handlePresetInfo(command)
        case .unknown:
            break
        }
    }

    // MARK: - Bypass States Refresh

    private func refreshBypassStates() async {
        await withCheckedContinuation { continuation in
            var pending: Set<Int> = Set(0..<8)
            var listenerId: UUID?

            listenerId = hid.addListener { [weak self] data in
                guard let self else { return }
                let command = PacketDecoder.decode(data)
                if case .bypassState(let slot, _) = command {
                    pending.remove(slot)
                    if pending.isEmpty {
                        if let id = listenerId { self.hid.removeListener(id) }
                        continuation.resume()
                    }
                }
            }

            Task {
                try? await hid.send(PacketBuilder.requestBypassStates())
                // Timeout after 1 second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if let id = listenerId { hid.removeListener(id) }
                continuation.resume()
            }
        }
    }
}
