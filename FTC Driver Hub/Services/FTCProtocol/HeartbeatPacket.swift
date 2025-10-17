//
//  HeartbeatPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct HeartbeatPacket {
    var peerType: Int8
    var token: Int16
    var sdkBuildMonth: Int8
    var sdkBuildYear: Int16
    var sdkMajorVersion: Int8
    var sdkMinorVersion: Int8

    func encode() -> Data {
        var d = Data()
        d.append(UInt8(124)) // static header byte
        d.append(UInt8(bitPattern: peerType))
        d.appendBE(token)
        d.append(UInt8(bitPattern: sdkBuildMonth))
        d.appendBE(sdkBuildYear)
        d.append(UInt8(bitPattern: sdkMajorVersion))
        d.append(UInt8(bitPattern: sdkMinorVersion))
        d.append(UInt8(0)) // padding byte
        return d
    }

    static func read(from data: inout Data) -> HeartbeatPacket? {
        guard data.readUInt8() != nil,
              let pt = data.readInt8(),
              let token = data.readInt16(),
              let month = data.readInt8(),
              let year = data.readInt16(),
              let maj = data.readInt8(),
              let min = data.readInt8(),
              data.readUInt8() != nil
        else { return nil }

        return HeartbeatPacket(peerType: pt, token: token,
                               sdkBuildMonth: month, sdkBuildYear: year,
                               sdkMajorVersion: maj, sdkMinorVersion: min)
    }
}
