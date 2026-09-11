// MustangHIDManager.swift
// Equivalente di protocol.ts — gestisce la connessione USB HID via IOKit

import Foundation
import IOKit
import IOKit.hid

// MARK: - Types

typealias HIDCallback = ([UInt8]) -> Void

// MARK: - MustangHIDManager

@MainActor
final class MustangHIDManager: ObservableObject {
    private var hidManager: IOHIDManager?
    private var hidDevice: IOHIDDevice?
    private var sequenceId: UInt8 = 0
    private var listeners: [UUID: HIDCallback] = [:]

    @Published private(set) var isConnected: Bool = false

    var isSupported: Bool { true } // IOKit sempre disponibile su macOS

    // MARK: - Connect

    func connect() async -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, [
            kIOHIDVendorIDKey: FENDER_VID
        ] as CFDictionary)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            print("[HID] Failed to open manager: \(openResult)")
            return false
        }

        self.hidManager = manager

        // Enumerate connected devices
        guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
              let device = deviceSet.first else {
            print("[HID] No Fender device found")
            return false
        }

        let openDev = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
        guard openDev == kIOReturnSuccess else {
            print("[HID] Failed to open device: \(openDev)")
            return false
        }

        self.hidDevice = device
        self.isConnected = true

        // Register input report callback
        registerInputCallback(device)

        // Handshake
        try? await send(PacketBuilder.handshake1())
        try? await send(PacketBuilder.handshake2())

        print("[HID] Connected to Fender Mustang")
        return true
    }

    // MARK: - Disconnect

    func disconnect() async {
        if let device = hidDevice {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            hidDevice = nil
        }
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            hidManager = nil
        }
        listeners.removeAll()
        isConnected = false
        print("[HID] Disconnected")
    }

    // MARK: - Send

    func send(_ packet: [UInt8]) async throws {
        guard let device = hidDevice else {
            throw NSError(domain: "MustangHID", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        var data = packet
        // Pad to 64 bytes if needed
        while data.count < PACKET_SIZE { data.append(0x00) }

        let result = data.withUnsafeBytes { ptr in
            IOHIDDeviceSetReport(device,
                                 kIOHIDReportTypeOutput,
                                 0,
                                 ptr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                                 data.count)
        }
        if result != kIOReturnSuccess {
            print("[HID] Send error: \(result)")
            throw NSError(domain: "MustangHID", code: Int(result))
        }
    }

    // MARK: - Sequence ID

    func nextSequenceId() -> UInt8 {
        sequenceId = (sequenceId &+ 1) & 0xff
        return sequenceId
    }

    // MARK: - Listeners

    func addListener(_ callback: @escaping HIDCallback) -> UUID {
        let id = UUID()
        listeners[id] = callback
        return id
    }

    func removeListener(_ id: UUID) {
        listeners.removeValue(forKey: id)
    }

    // MARK: - IOKit Callback

    private func registerInputCallback(_ device: IOHIDDevice) {
        let context = Unmanaged.passUnretained(self).toOpaque()

        IOHIDDeviceRegisterInputReportCallback(
            device,
            UnsafeMutablePointer<UInt8>.allocate(capacity: PACKET_SIZE),
            PACKET_SIZE,
            { context, result, sender, type, reportId, report, reportLength in
                guard let ctx = context else { return }
                let manager = Unmanaged<MustangHIDManager>.fromOpaque(ctx).takeUnretainedValue()
                let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))
                Task { @MainActor in
                    manager.dispatchInput(bytes)
                }
            },
            context
        )
    }

    private func dispatchInput(_ data: [UInt8]) {
        for callback in listeners.values {
            callback(data)
        }
    }
}
