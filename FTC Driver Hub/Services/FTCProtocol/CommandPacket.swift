//
//  CommandPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct CommandPacket {
    var timestamp: UInt64
    var acknowledged: Bool
    var command: String
    var data: String

    func encode() -> Data {
        var d = Data()
        d.appendBE(timestamp)
        d.append(UInt8(acknowledged ? 1 : 0))
        d.appendBE(UInt16(command.utf8.count))
        d.appendString(command)
        if !acknowledged {
            d.appendBE(UInt16(data.utf8.count))
            d.appendString(data)
        }
        return d
    }

    static func read(from data: inout Data) -> CommandPacket? {
        guard let ts = data.readUInt64(),
              let ackRaw = data.readUInt8(),
              let cmdLen = data.readUInt16(),
              let cmd = data.readString(length: Int(cmdLen))
        else { return nil }

        var dat = ""
        if ackRaw == 0, let datLen = data.readUInt16(),
           let s = data.readString(length: Int(datLen)) {
            dat = s
        }
        return CommandPacket(timestamp: ts, acknowledged: ackRaw != 0, command: cmd, data: dat)
    }
}
