//
//  PacketRouter.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

enum PacketType: UInt8 {
    case time = 1
    case gamepad = 2
    case heartbeat = 3
    case command = 4
    case telemetry = 5
}

enum DecodedPacket {
    case time(TimePacket)
    case gamepad(GamepadPacket)
    case heartbeat(HeartbeatPacket)
    case command(CommandPacket)
    case telemetry(TelemetryPacket)
}

struct PacketRouter {
    static func decode(_ data: Data) -> DecodedPacket? {
        guard let env = PacketEnvelope.decode(from: data),
              let type = PacketType(rawValue: env.type)
        else { return nil }

        var payload = env.payload
        switch type {
        case .time:
            return TimePacket.read(from: &payload).map { .time($0) }
        case .gamepad:
            return GamepadPacket.read(from: &payload).map { .gamepad($0) }
        case .heartbeat:
            return HeartbeatPacket.read(from: &payload).map { .heartbeat($0) }
        case .command:
            return CommandPacket.read(from: &payload).map { .command($0) }
        case .telemetry:
            return TelemetryPacket(from: payload).map { .telemetry($0) }
        }
    }
}
