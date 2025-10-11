//
//  TelemetryPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct TelemetryPacket: Packet {
    static let id: PacketType = .telemetry

    var unixTimestampMillis: Int64
    var isSorted: Bool
    var robotState: RobotOpModeState
    var tag: String
    var stringEntries: [TelemetryEntry]
    var floatEntries: [FloatEntry]
    
    init(unixTimestampMillis: Int64, isSorted: Bool,
        robotState: RobotOpModeState, tag: String,
        stringEntries: [TelemetryEntry], floatEntries: [FloatEntry]) {
        self.unixTimestampMillis = unixTimestampMillis
        self.isSorted = isSorted
        self.robotState = robotState
        self.tag = tag
        self.stringEntries = stringEntries
        self.floatEntries = floatEntries
    }

    // MARK: - Decode (inbound only)
    init?(data rawData: Data) {
        var cursor = 1 // skip packet ID
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            defer { cursor += size }
            return rawData[cursor..<cursor + size].withUnsafeBytes { $0.load(as: T.self) }
        }

        func readString(length: Int) -> String {
            let range = cursor..<cursor + length
            let strData = rawData.subdata(in: range)
            cursor += length
            return String(data: strData, encoding: .utf8) ?? ""
        }

        guard rawData.count >= 10 else { return nil }

        unixTimestampMillis = Int64(littleEndian: read(Int64.self))
        isSorted = read(UInt8.self) != 0
        robotState = RobotOpModeState(rawValue: read(Int8.self)) ?? .unknown

        let tagLen = Int(read(UInt8.self))
        tag = tagLen > 0 ? readString(length: tagLen) : ""

        let numStringEntries = Int(read(UInt8.self))
        var stringEntriesTemp: [TelemetryEntry] = []

        for _ in 0..<numStringEntries {
            guard let entry = TelemetryEntry.read(from: &cursor, data: rawData) else { return nil }
            stringEntriesTemp.append(entry)
        }

        let numFloatEntries = Int(read(UInt8.self))
        var floatEntriesTemp: [FloatEntry] = []

        for _ in 0..<numFloatEntries {
            guard let entry = FloatEntry.read(from: &cursor, data: rawData) else { return nil }
            floatEntriesTemp.append(entry)
        }

        stringEntries = stringEntriesTemp
        floatEntries = floatEntriesTemp
    }

    func encode() -> Data { Data() } // Telemetry is inbound-only
}
