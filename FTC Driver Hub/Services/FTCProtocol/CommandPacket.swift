//
//  CommandPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct CommandPacket: Packet {
    static let id: PacketType = .command

    var timestamp: UInt64
    var acknowledged: Bool
    var command: String
    var data: String
    
    init(timestamp: UInt64, acknowledged: Bool, command: String, data: String) {
        self.timestamp = timestamp
        self.acknowledged = acknowledged
        self.command = command
        self.data = data
    }

    // MARK: - Encode
    func encode() -> Data {
        var dataOut = Data([Self.id.rawValue])

        var ts = timestamp.littleEndian
        withUnsafeBytes(of: &ts) { dataOut.append(contentsOf: $0) }

        var ack: UInt8 = acknowledged ? 1 : 0
        withUnsafeBytes(of: &ack) { dataOut.append(contentsOf: $0) }

        let commandBytes = command.data(using: .utf8) ?? Data()
        var cmdLen = UInt16(commandBytes.count).littleEndian
        withUnsafeBytes(of: &cmdLen) { dataOut.append(contentsOf: $0) }
        dataOut.append(commandBytes)

        if !acknowledged {
            let dataBytes = self.data.data(using: .utf8) ?? Data()
            var dataLen = UInt16(dataBytes.count).littleEndian
            withUnsafeBytes(of: &dataLen) { dataOut.append(contentsOf: $0) }
            if !dataBytes.isEmpty {
                dataOut.append(dataBytes)
            }
        }

        return dataOut
    }

    // MARK: - Decode
    init?(data rawData: Data) {
        var cursor = 1 // skip packet ID
        
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            defer { cursor += size }
            return rawData[cursor..<cursor + size].withUnsafeBytes { $0.load(as: T.self) }
        }
        
        timestamp = UInt64(littleEndian: read(UInt64.self))
        acknowledged = read(UInt8.self) != 0
        
        let cmdLen = Int(UInt16(littleEndian: read(UInt16.self)))
        guard cursor + cmdLen <= rawData.count else { return nil }
        let cmdBytes = rawData[cursor..<cursor + cmdLen]
        cursor += cmdLen
        command = String(data: cmdBytes, encoding: .utf8) ?? ""
        
        if !acknowledged {
            let dataLen = Int(UInt16(littleEndian: read(UInt16.self)))
            guard cursor + dataLen <= rawData.count else { return nil }
            let payloadBytes = rawData[cursor..<cursor + dataLen]
            self.data = String(data: payloadBytes, encoding: .utf8) ?? ""
        } else {
            self.data = ""
        }
    }
}
