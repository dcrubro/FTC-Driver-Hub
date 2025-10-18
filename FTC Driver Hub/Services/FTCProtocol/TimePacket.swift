//
//  TimePacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct TimePacket {
    var timestamp: UInt64
    var robotOpModeState: RobotOpModeState
    var unixMillisSent: UInt64
    var unixMillisReceived1: UInt64
    var unixMillisReceived2: UInt64
    var timezone: String

    func encode() -> Data {
        var d = Data()
        d.appendBE(timestamp)
        d.append(UInt8(bitPattern: robotOpModeState.rawValue))
        d.appendBE(unixMillisSent)
        d.appendBE(unixMillisReceived1)
        d.appendBE(unixMillisReceived2)

        let tzData = timezone.data(using: .utf8) ?? Data()
        d.append(UInt8(tzData.count))
        d.append(tzData)
        
        return d
    }

    static func read(from data: inout Data) -> TimePacket? {
        guard
            let timestamp = data.readUInt64(),
            let robotState = data.readInt8(),
            let unixSent = data.readUInt64(),
            let recv1 = data.readUInt64(),
            let recv2 = data.readUInt64(),
            let tzLen = data.readUInt8(),
            let tz = data.readString(length: Int(tzLen))
        else {
            return nil
        }

        return TimePacket(
            timestamp: timestamp,
            robotOpModeState: RobotOpModeState(rawValue: robotState) ?? .unknown,
            unixMillisSent: unixSent,
            unixMillisReceived1: recv1,
            unixMillisReceived2: recv2,
            timezone: tz
        )
    }
}
