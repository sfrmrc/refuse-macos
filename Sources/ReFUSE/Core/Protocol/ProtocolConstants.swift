// ProtocolConstants.swift
// Migrazione 1:1 di constants.ts

import Foundation

/// USB Vendor ID Fender
let FENDER_VID: Int = 0x1ed8

/// Dimensione fissa di ogni pacchetto HID (byte)
let PACKET_SIZE: Int = 64

enum OPCODES {
    static let HANDSHAKE_1:         UInt8 = 0xc3
    static let HANDSHAKE_2_BYTE1:   UInt8 = 0x1a
    static let HANDSHAKE_2_BYTE2:   UInt8 = 0x03

    static let REQUEST_STATE:       UInt8 = 0xff
    static let REQUEST_STATE_BYTE2: UInt8 = 0xc1
    static let REQUEST_BYPASS:      UInt8 = 0x19
    static let REQUEST_BYPASS_BYTE2:UInt8 = 0x00

    static let DATA_PACKET:         UInt8 = 0x1c
    static let DATA_WRITE:          UInt8 = 0x03
    static let DATA_READ:           UInt8 = 0x01
    static let PRESET_INFO:         UInt8 = 0x04

    static let BYPASS_PACKET:       UInt8 = 0x19
    static let BYPASS_SET:          UInt8 = 0xc3
    static let BYPASS_RESPONSE:     UInt8 = 0xc3
}

enum OFFSETS {
    static let COMMAND:         Int = 0
    static let SUB_COMMAND:     Int = 1
    static let TYPE:            Int = 2

    static let PRESET_SLOT:     Int = 4
    static let PRESET_NAME:     Int = 16

    static let MODEL_ID_MSB:    Int = 16
    static let MODEL_ID_LSB:    Int = 17
    static let SLOT_INDEX:      Int = 18
    static let BYPASS:          Int = 22

    static let KNOB_START:      Int = 32
    static let KNOB_END:        Int = 64
    static let KNOB_COUNT:      Int = 32

    static let CABINET_ID:      Int = 49

    static let LIVE_KNOB_INDEX: Int = 5
    static let LIVE_KNOB_VALUE: Int = 10
    static let LIVE_SLOT_INDEX: Int = 13
}

enum VALUES {
    static let BYPASSED: UInt8 = 1
    static let ENABLED:  UInt8 = 0
}
