//
//  ButtonFlags.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

struct ButtonFlags: OptionSet {
    let rawValue: UInt32

    static let rightBumper         = ButtonFlags(rawValue: 1 << 0)
    static let leftBumper          = ButtonFlags(rawValue: 1 << 1)
    static let back                = ButtonFlags(rawValue: 1 << 2)
    static let start               = ButtonFlags(rawValue: 1 << 3)
    static let guide               = ButtonFlags(rawValue: 1 << 4)
    static let y                   = ButtonFlags(rawValue: 1 << 5)
    static let x                   = ButtonFlags(rawValue: 1 << 6)
    static let b                   = ButtonFlags(rawValue: 1 << 7)
    static let a                   = ButtonFlags(rawValue: 1 << 8)
    static let dpadRight           = ButtonFlags(rawValue: 1 << 9)
    static let dpadLeft            = ButtonFlags(rawValue: 1 << 10)
    static let dpadDown            = ButtonFlags(rawValue: 1 << 11)
    static let dpadUp              = ButtonFlags(rawValue: 1 << 12)
    static let rightStickButton    = ButtonFlags(rawValue: 1 << 13)
    static let leftStickButton     = ButtonFlags(rawValue: 1 << 14)
    static let touchpad            = ButtonFlags(rawValue: 1 << 15)
    static let touchpadFinger2     = ButtonFlags(rawValue: 1 << 16)
    static let touchpadFinger1     = ButtonFlags(rawValue: 1 << 17)
}
