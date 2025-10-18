//
//  CommandPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct CommandPacket: Equatable, CustomStringConvertible {
    let timestamp: UInt64
    let acknowledged: Bool
    let command: String
    let data: String

    // MARK: - Encoding (Writeable)
    func encode() -> Data {
        var buffer = Data()
        buffer.appendBE(timestamp)
        buffer.append(UInt8(acknowledged ? 1 : 0))

        // Command string
        let cmdData = Data(command.utf8)
        buffer.appendBE(UInt16(cmdData.count))
        buffer.append(cmdData)

        // Only include data if not acknowledged
        if !acknowledged {
            let dataBytes = Data(data.utf8)
            buffer.appendBE(UInt16(dataBytes.count))
            if !dataBytes.isEmpty {
                buffer.append(dataBytes)
            }
        }

        return buffer
    }

    // MARK: - Decoding (Readable)
    static func decode(from data: inout Data) -> CommandPacket? {
        guard let timestamp = data.readUInt64(),
              let ackByte = data.readUInt8() else { return nil }

        let acknowledged = ackByte != 0
        guard let cmdLen = data.readUInt16(),
              let command = data.readString(length: Int(cmdLen)) else { return nil }

        var body = ""
        if !acknowledged {
            guard let dataLen = data.readUInt16(),
                  let str = data.readString(length: Int(dataLen)) else { return nil }
            body = str
        }

        return CommandPacket(
            timestamp: timestamp,
            acknowledged: acknowledged,
            command: command,
            data: body
        )
    }

    // MARK: - Utility
    var description: String {
        "CommandPacket(cmd: \(command), data: \(data), ack: \(acknowledged))"
    }
}
