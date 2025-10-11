//
//  PacketRouter.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

enum PacketEnvelope {
    case time(TimePacket)
    case gamepad(GamepadPacket)        // rarely used inbound, but supported
    case heartbeat(HeartbeatPacket)    // rarely used inbound, but supported
    case command(CommandPacket)
    case telemetry(TelemetryPacket)
}

struct PacketRouter {
    static func decode(_ rawData: Data) -> PacketEnvelope? {
        guard let type = PacketType(rawValue: rawData.first ?? 0) else { return nil }

        switch type {
        case .time:
            return TimePacket(data: rawData).map { .time($0) }
        case .gamepad:
            return GamepadPacket(data: rawData).map { .gamepad($0) } // outbound-only usually
        case .heartbeat:
            return HeartbeatPacket(data: rawData).map { .heartbeat($0) } // outbound-only usually
        case .command:
            return CommandPacket(data: rawData).map { .command($0) }
        case .telemetry:
            return TelemetryPacket(data: rawData).map { .telemetry($0) }
        }
    }
}
