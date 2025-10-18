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

struct RoutedPacket {
    let type: UInt8
    let sequenceNumber: Int16?
    let payload: Any
}

struct PacketRouter {
    static func decode(_ data: Data) -> RoutedPacket? {
            guard let env = PacketEnvelope.decode(from: data) else { return nil }
            var payload = env.payload

            switch env.type {
            case 0x01: // Time Packet
                if let packet = TimePacket.read(from: &payload) {
                    return RoutedPacket(type: env.type, sequenceNumber: env.sequenceNumber, payload: packet)
                }

            case 0x02: // Gamepad Packet
                if let packet = GamepadPacket.read(from: &payload) {
                    return RoutedPacket(type: env.type, sequenceNumber: env.sequenceNumber, payload: packet)
                }

            case 0x03: // Heartbeat Packet
                if let packet = HeartbeatPacket.read(from: &payload) {
                    return RoutedPacket(type: env.type, sequenceNumber: env.sequenceNumber, payload: packet)
                }

            case 0x04: // Command Packet
                if let packet = CommandPacket.decode(from: &payload) {
                    return RoutedPacket(type: env.type, sequenceNumber: env.sequenceNumber, payload: packet)
                }

            case 0x05: // Telemetry Packet
                if let packet = TelemetryPacket(from: payload) {
                    return RoutedPacket(type: env.type, sequenceNumber: env.sequenceNumber, payload: packet)
                }

            default:
                print("[PacketRouter] ⚠️ Unknown packet type: \(env.type)")
                return nil
            }

            return nil
        }
}
