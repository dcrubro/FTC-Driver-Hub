//
//  TelemetryPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct TelemetryPacket {
    let unixMillis: UInt64
    let isSorted: Bool
    let robotState: Int8
    let tag: String?
    var stringEntries: [TelemetryEntry]
    var floatEntries: [FloatEntry]

    init?(from data: Data) {
        var d = data

        // 8 bytes: unixMillis
        guard let unixMillis = d.readUInt64() else { return nil }
        self.unixMillis = unixMillis

        // 1 byte: isSorted
        guard let sortedFlag = d.readUInt8() else { return nil }
        self.isSorted = sortedFlag != 0

        // 1 byte: robotState
        guard let state = d.readInt8() else { return nil }
        self.robotState = state

        // 1 byte: tag length
        guard let tagLen = d.readUInt8() else { return nil }

        // variable: tag (if > 0)
        if tagLen > 0 {
            self.tag = d.readString(length: Int(tagLen))
        } else {
            self.tag = nil
        }

        // Now parse string entries
        self.stringEntries = TelemetryPacket.parseStringEntries(from: &d)

        // Then float entries (usually 0)
        self.floatEntries = TelemetryPacket.parseFloatEntries(from: &d)
    }

    // MARK: - Parsing helpers

    private static func parseStringEntries(from data: inout Data) -> [TelemetryEntry] {
        guard let entryCount = data.readUInt8() else { return [] }
        var entries: [TelemetryEntry] = []

        for _ in 0..<entryCount {
            guard let keyLen = data.readUInt16(),
                  let key = data.readString(length: Int(keyLen)),
                  let valLen = data.readUInt16(),
                  let value = data.readString(length: Int(valLen)) else {
                break
            }
            entries.append(TelemetryEntry(key: key, value: value))
        }

        return entries
    }

    private static func parseFloatEntries(from data: inout Data) -> [FloatEntry] {
        guard let entryCount = data.readUInt8() else { return [] }
        var floats: [FloatEntry] = []

        for _ in 0..<entryCount {
            guard let keyLen = data.readUInt16(),
                  let key = data.readString(length: Int(keyLen)),
                  let value = data.readFloat32() else {
                break
            }
            floats.append(FloatEntry(key: key, value: value))
        }

        return floats
    }
}
