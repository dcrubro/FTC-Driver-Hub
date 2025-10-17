//
//  OpModeStates.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation

enum RobotOpModeState: Int8, Codable {
    case unknown = -1
    case notStarted = 0
    case initialized = 1
    case running = 2
    case stopped = 3
    case emergencyStopped = 4
}
