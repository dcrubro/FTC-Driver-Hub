//
//  GamepadPacket.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct GamepadPacket: Packet {
    static let id: PacketType = .gamepad

    var gamepadID: Int32
    var timestamp: UInt64
    var leftStickX: Float
    var leftStickY: Float
    var rightStickX: Float
    var rightStickY: Float
    var leftTrigger: Float
    var rightTrigger: Float
    var buttonFlags: UInt32
    var user: UInt8
    var legacyType: UInt8
    var gamepadType: UInt8
    var touchpadFinger1X: Float
    var touchpadFinger1Y: Float
    var touchpadFinger2X: Float
    var touchpadFinger2Y: Float

    init(gamepadID: Int32, timestamp: UInt64,
        leftStickX: Float, leftStickY: Float,
        rightStickX: Float, rightStickY: Float,
        leftTrigger: Float, rightTrigger: Float,
        buttonFlags: UInt32, user: UInt8,
        legacyType: UInt8, gamepadType: UInt8,
        touchpadFinger1X: Float, touchpadFinger1Y: Float,
        touchpadFinger2X: Float, touchpadFinger2Y: Float) {
        self.gamepadID = gamepadID
        self.timestamp = timestamp
        self.leftStickX = leftStickX
        self.leftStickY = leftStickY
        self.rightStickX = rightStickX
        self.rightStickY = rightStickY
        self.leftTrigger = leftTrigger
        self.rightTrigger = rightTrigger
        self.buttonFlags = buttonFlags
        self.user = user
        self.legacyType = legacyType
        self.gamepadType = gamepadType
        self.touchpadFinger1X = touchpadFinger1X
        self.touchpadFinger1Y = touchpadFinger1Y
        self.touchpadFinger2X = touchpadFinger2X
        self.touchpadFinger2Y = touchpadFinger2Y
    }
    
    // MARK: - Encode
    func encode() -> Data {
        var data = Data([Self.id.rawValue])
        var marker: UInt8 = 5
        withUnsafeBytes(of: &marker) { data.append(contentsOf: $0) }

        var gid = gamepadID.littleEndian
        var ts = timestamp.littleEndian
        [gid, ts].forEach { withUnsafeBytes(of: $0) { data.append(contentsOf: $0) } }

        for f in [leftStickX, leftStickY, rightStickX, rightStickY,
                  leftTrigger, rightTrigger,
                  touchpadFinger1X, touchpadFinger1Y,
                  touchpadFinger2X, touchpadFinger2Y] {
            var bits = f.bitPattern.littleEndian
            withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
        }

        var flags = buttonFlags.littleEndian
        withUnsafeBytes(of: &flags) { data.append(contentsOf: $0) }

        [user, legacyType, gamepadType].forEach { v in
            var val = v
            withUnsafeBytes(of: &val) { data.append(contentsOf: $0) }
        }

        return data
    }
    
    // MARK: - Decode
    // Not really needed here
    init?(data: Data) {
        return nil
    }
}
