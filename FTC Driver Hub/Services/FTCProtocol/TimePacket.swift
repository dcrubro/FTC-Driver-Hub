//
//  TimePacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct TimePacket: Packet {
    static let id: PacketType = .time
    
    var timestamp: UInt64
    var robotOpModeState: RobotOpModeState
    var unixMillisSent: UInt64
    var unixMillisReceived1: UInt64
    var unixMillisReceived2: UInt64
    var timezone: String
    
    // Explicit memberwise initializer
    init(timestamp: UInt64, robotOpModeState: RobotOpModeState,
        unixMillisSent: UInt64, unixMillisReceived1: UInt64,
        unixMillisReceived2: UInt64, timezone: String) {
        self.timestamp = timestamp
        self.robotOpModeState = robotOpModeState
        self.unixMillisSent = unixMillisSent
        self.unixMillisReceived1 = unixMillisReceived1
        self.unixMillisReceived2 = unixMillisReceived2
        self.timezone = timezone
    }
    
    // MARK: Encode
    func encode() -> Data {
        var data = Data([Self.id.rawValue])
        var timestampLE = timestamp.littleEndian
        var opMode = robotOpModeState.rawValue
        var sentLE = unixMillisSent.littleEndian
        var recv1LE = unixMillisReceived1.littleEndian
        var recv2LE = unixMillisReceived2.littleEndian
        var tzData = timezone.data(using: .utf8) ?? Data()
        var tzLength = UInt8(tzData.count)
        
        withUnsafeBytes(of: &timestampLE) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &opMode) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &sentLE) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &recv1LE) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &recv2LE) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &tzLength) { data.append(contentsOf: $0) }
        data.append(tzData)

        return data
    }
    
    // MARK: Decode
    init?(data: Data) {
        var cursor = 1 // skip packet ID
        guard data.count > cursor + 8 else { return nil }

        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            defer { cursor += size }
            return data[cursor..<cursor + size].withUnsafeBytes {
                $0.load(as: T.self)
            }
        }

        timestamp = UInt64(littleEndian: read(UInt64.self))
        robotOpModeState = RobotOpModeState(rawValue: read(Int8.self)) ?? .unknown
        unixMillisSent = UInt64(littleEndian: read(UInt64.self))
        unixMillisReceived1 = UInt64(littleEndian: read(UInt64.self))
        unixMillisReceived2 = UInt64(littleEndian: read(UInt64.self))
        let tzLength = Int(read(UInt8.self))
        guard cursor + tzLength <= data.count else { return nil }
        let tzBytes = data[cursor..<cursor + tzLength]
        timezone = String(data: tzBytes, encoding: .utf8) ?? "Unknown"
    }
}
