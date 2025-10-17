//
//  PacketEnvelope.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 17. 10. 25.
//

import Foundation

struct PacketEnvelope {
    let type: UInt8
    let sequenceNumber: Int16?
    let payload: Data

    func encode() -> Data {
        var buffer = Data()
        buffer.append(type)
        buffer.appendBE(UInt16(payload.count))
        if let seq = sequenceNumber {
            buffer.appendBE(seq)
        }
        buffer.append(payload)
        return buffer
    }

    static func decode(from data: Data) -> PacketEnvelope? {
        guard data.count >= 3 else { return nil }
        var temp = data
        let type = temp.removeFirst()
        guard let length = temp.readUInt16() else { return nil }

        var seq: Int16? = nil
        if type != 3, let s = temp.readInt16() {
            seq = s
        }

        let payload = temp.prefix(Int(length))
        return PacketEnvelope(type: type, sequenceNumber: seq, payload: Data(payload))
    }
}
