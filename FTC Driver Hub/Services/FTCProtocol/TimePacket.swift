//
//  TimePacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct TimePacket {
    var timestamp: UInt64
    var robotState: RobotOpModeState
    var unixMillisSent: UInt64
    var unixMillisReceived1: UInt64
    var unixMillisReceived2: UInt64
    var timezone: String

    func encode() -> Data {
        var d = Data()
        d.appendBE(timestamp)
        d.append(UInt8(bitPattern: robotState.rawValue))
        d.appendBE(unixMillisSent)
        d.appendBE(unixMillisReceived1)
        d.appendBE(unixMillisReceived2)
        d.append(UInt8(timezone.utf8.count))
        d.appendString(timezone)
        return d
    }

    static func read(from data: inout Data) -> TimePacket? {
        guard let ts = data.readUInt64(),
              let stateRaw = data.readInt8(),
              let s1 = data.readUInt64(),
              let s2 = data.readUInt64(),
              let s3 = data.readUInt64(),
              let tzLen = data.readUInt8(),
              let tz = data.readString(length: Int(tzLen))
        else { return nil }

        return TimePacket(
            timestamp: ts,
            robotState: RobotOpModeState(rawValue: stateRaw) ?? .unknown,
            unixMillisSent: s1,
            unixMillisReceived1: s2,
            unixMillisReceived2: s3,
            timezone: tz
        )
    }
}
