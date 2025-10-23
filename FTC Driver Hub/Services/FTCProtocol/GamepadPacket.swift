//
//  GamepadPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct GamepadPacket {
    var gamepadID: Int32
    var timestamp: UInt64
    var leftStickX, leftStickY, rightStickX, rightStickY: Float
    var leftTrigger, rightTrigger: Float
    var buttonFlags: UInt32
    var user, legacyType, gamepadType: UInt8
    var touch1X, touch1Y, touch2X, touch2Y: Float

    func encode() -> Data {
        var d = Data()
        d.append(UInt8(bitPattern: Int8(5)))
        d.appendBE(gamepadID)
        d.appendBE(timestamp)

        func appendF(_ f: Float) {
            var bits = f.bitPattern.bigEndian
            Swift.withUnsafeBytes(of: &bits) { d.append(contentsOf: $0) }
        }

        [leftStickX, leftStickY, rightStickX, rightStickY,
         leftTrigger, rightTrigger].forEach(appendF)

        d.appendBE(buttonFlags)
        d.append(user)
        d.append(legacyType)
        d.append(gamepadType)

        [touch1X, touch1Y, touch2X, touch2Y].forEach(appendF)
        return d
    }

    static func read(from data: inout Data) -> GamepadPacket? {
        guard data.count >= 69 else { return nil }
        _ = data.readUInt8() // static 5
        
        guard let id = data.readInt32(),
              let ts = data.readUInt64()
        else { return nil }
        
        func readF() -> Float? { data.readFloat32() }

        guard let lx = readF(), let ly = readF(),
              let rx = readF(), let ry = readF(),
              let lt = readF(), let rt = readF(),
              let flags = data.readUInt32(),
              let user = data.readUInt8(),
              let legacy = data.readUInt8(),
              let type = data.readUInt8(),
              let t1x = readF(), let t1y = readF(),
              let t2x = readF(), let t2y = readF()
        else { return nil }

        return GamepadPacket(
            gamepadID: id, timestamp: ts,
            leftStickX: lx, leftStickY: ly,
            rightStickX: rx, rightStickY: ry,
            leftTrigger: lt, rightTrigger: rt,
            buttonFlags: flags,
            user: user, legacyType: legacy, gamepadType: type,
            touch1X: t1x, touch1Y: t1y,
            touch2X: t2x, touch2Y: t2y
        )
    }
}
