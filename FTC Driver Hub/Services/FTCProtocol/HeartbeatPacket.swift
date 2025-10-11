//
//  HeartbeatPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct HeartbeatPacket: Packet {
    static let id: PacketType = .heartbeat

    var peerType: Int8        // 1 = peer, 2 = group owner, etc.
    var sequenceNumber: Int16 // 10003 for requests, 7 for responses
    var sdkBuildMonth: Int8
    var sdkBuildYear: Int16
    var sdkMajorVersion: Int8
    var sdkMinorVersion: Int8
    
    init(peerType: Int8, sequenceNumber: Int16,
        sdkBuildMonth: Int8, sdkBuildYear: Int16,
        sdkMajorVersion: Int8, sdkMinorVersion: Int8) {
        self.peerType = peerType
        self.sequenceNumber = sequenceNumber
        self.sdkBuildMonth = sdkBuildMonth
        self.sdkBuildYear = sdkBuildYear
        self.sdkMajorVersion = sdkMajorVersion
        self.sdkMinorVersion = sdkMinorVersion
    }

    // MARK: - Encode
    func encode() -> Data {
        var data = Data([Self.id.rawValue])
        var marker: UInt8 = 124
        withUnsafeBytes(of: &marker) { data.append(contentsOf: $0) }

        var pt = peerType
        var seq = sequenceNumber.littleEndian
        var month = sdkBuildMonth
        var year = sdkBuildYear.littleEndian
        var major = sdkMajorVersion
        var minor = sdkMinorVersion
        var terminator: UInt8 = 0

        withUnsafeBytes(of: &pt) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &seq) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &month) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &year) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &major) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &minor) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &terminator) { data.append(contentsOf: $0) }

        return data
    }

    // MARK: - Decode (optional)
    init?(data: Data) {
        var cursor = 1 // skip packet ID
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            defer { cursor += size }
            return data[cursor..<cursor+size].withUnsafeBytes { $0.load(as: T.self) }
        }

        let marker = read(UInt8.self)
        guard marker == 124 else { return nil }

        peerType = read(Int8.self)
        sequenceNumber = Int16(littleEndian: read(Int16.self))
        sdkBuildMonth = read(Int8.self)
        sdkBuildYear = Int16(littleEndian: read(Int16.self))
        sdkMajorVersion = read(Int8.self)
        sdkMinorVersion = read(Int8.self)
        _ = read(UInt8.self) // trailing 0
    }
}
