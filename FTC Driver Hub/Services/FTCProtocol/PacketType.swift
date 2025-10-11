//
//  PacketType.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

enum PacketType: UInt8 {
    case time = 0x01
    case gamepad = 0x02
    case heartbeat = 0x03
    case command = 0x04
    case telemetry = 0x05
}
