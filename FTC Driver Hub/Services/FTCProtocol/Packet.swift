//
//  Packet.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

protocol Packet {
    static var id: PacketType { get }
    func encode() -> Data
    init?(data: Data)
}
