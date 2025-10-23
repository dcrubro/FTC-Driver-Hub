//
//  FTCController.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import SwiftUI
import Combine

/*struct OpModeData: Codable {
    let flavor: String
    let group: String
    let name: String
    let source: String?
    let systemOpModeBaseDisplayName: String?
}*/

@MainActor
final class FTCController: ObservableObject {
    @Published var telemetry = Telemetry(batteryVoltage: 0, status: "Null")
    @Published var logs: [String] = []
    @Published var settings = Settings(ipAddress: "192.168.43.1", port: "20884")
    @Published var isConnected = false

    @Published var opModes: [OpModeData] = []
    @Published var selectedOpMode: String? = nil
    @Published var robotState: RobotOpModeState = .unknown
    @Published var latestTelemetry: [String: String] = [:]
    @Published var lastErrorMessage: String? = nil
    @Published var showErrorAlert: Bool = false

    private var engine: ProtocolEngine?

    func connect() {
        guard !isConnected else { return }
        logs.append("Connecting to \(settings.ipAddress):\(settings.port)...")

        let cfg = ProtocolEngine.Config(
            host: settings.ipAddress,
            port: UInt16(settings.port) ?? 20884
        )

        //let engine = ProtocolEngine(config: cfg)
        let engine = ProtocolEngine(config: cfg)
        
        // MARK: - Telemetry updates
        engine.onTelemetry = { [weak self] packet in
            guard let self else { return }
            
            self.logs.append("Got Raw Telemetry!")

            for entry in packet.stringEntries {
                if entry.key == "$Robot$Battery$Level$",
                   let voltage = Double(entry.value) {
                    DispatchQueue.main.async {
                        self.telemetry.batteryVoltage = voltage
                    }
                    self.logs.append("Robot Battery: \(voltage)V")
                    print("Robot Battery: \(voltage)V")
                } else if entry.key == "Status" {
                    DispatchQueue.main.async {
                        self.telemetry.status = entry.value
                    }
                    
                    print("Robot Status: \(entry.value)")
                } else {
                    // General user-level telemetry, append to latest
                    print("\(entry.key): \(entry.value)")
                    var key: String = ""
                    var value: String = ""
                    
                    if entry.value.contains(":") {
                        let full: [String] = entry.value.components(separatedBy: ":")
                        key = full[0]
                        value = full[1]
                    } else {
                        key = entry.key
                        value = entry.value
                    }
                    
                    // Quick stupidity check
                    if key != "Status" {
                        // We're actually running lmao
                        self.latestTelemetry["Status "] = robotState == .running ? "Robot is running" : "Robot is initialized"
                    }
                    
                    DispatchQueue.main.async {
                        self.latestTelemetry[key] = value
                    }
                }
            }
        }

        // MARK: - Command handling
        engine.onCommand = { [weak self] (cmd: CommandPacket) in
            guard let self else { return }

            switch cmd.command {
            case CommandName.notifyOpModes:
                self.logs.append("Received OpMode list.")
                handleOpModeList(data: cmd.data)
            case CommandName.notifyOpModeState:
                self.logs.append("Robot state update: \(cmd.data)")
            case CommandName.notifyInitOpMode:
                robotState = .initialized
            case CommandName.notifyRunOpMode:
                if cmd.data == "$Stop$Robot$" {
                    robotState = .stopped
                } else {
                    robotState = .running
                }
            case CommandName.showStacktrace:
                if cmd.data.contains("Exception") {
                    let lines = cmd.data.split(separator: "\n").prefix(5)
                    self.lastErrorMessage = lines.joined(separator: "\n")
                }
                self.showErrorAlert = true
                self.logs.append("Robot Errored!")
            default:
                self.logs.append("Command received: \(cmd.command)")
            }
        }

        // MARK: - Heartbeat handling
        engine.onHeartbeat = { [weak self] (hb: HeartbeatPacket) in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isConnected = true
            }

            self.logs.append(
                "Heartbeat from Control Hub – SDK \(hb.sdkMajorVersion).\(hb.sdkMinorVersion), " +
                "Build \(hb.sdkBuildMonth)/\(hb.sdkBuildYear)"
            )
        }

        engine.start()
        self.engine = engine
        isConnected = true
        logs.append("Connected to \(settings.ipAddress):\(settings.port)")

        // Request opmode list once connected
        sendCommand("CMD_REQUEST_OP_MODE_LIST")
    }

    func disconnect() {
        engine?.stop()
        engine = nil
        isConnected = false
        logs.append("Disconnected")
    }

    // MARK: - Command sending helpers
    private func sendCommand(_ name: String, data: String = "", ack: Bool = false) {
        engine?.sendCommand(name: name, data: data, acknowledged: ack)
    }

    func initOpMode() {
        guard let opMode = selectedOpMode else { return }
        sendCommand(CommandName.initOpMode, data: opMode)
        logs.append("Init OpMode: \(opMode)")
    }

    func startOpMode() {
        guard let opMode = selectedOpMode else { return }
        sendCommand(CommandName.runOpMode, data: opMode)
        logs.append("Start OpMode: \(opMode)")
    }

    func stopOpMode() {
        sendCommand(CommandName.initOpMode, data: "$Stop$Robot$")
        logs.append("Stop OpMode")
    }
    
    // MARK: - Update Gamepad
    func updateGamepad(leftX: Double, leftY: Double,
                       rightX: Double, rightY: Double,
                       leftTrigger: Double = 0,
                       rightTrigger: Double = 0,
                       buttons: Set<String> = []) {
        guard let engine else { return }

        engine.updateGamepad { gp in
            gp.leftStickX = Float(leftX)
            gp.leftStickY = Float(leftY)
            gp.rightStickX = Float(rightX)
            gp.rightStickY = Float(rightY)
            gp.leftTrigger = Float(leftTrigger)
            gp.rightTrigger = Float(rightTrigger)

            // Map button names → bit flags
            var flags: UInt32 = 0
            if buttons.contains("triangle") { flags |= 1 << 5 }
            if buttons.contains("square")   { flags |= 1 << 6 }
            if buttons.contains("circle")   { flags |= 1 << 7 }
            if buttons.contains("cross")    { flags |= 1 << 8 }
            if buttons.contains("l1")       { flags |= 1 << 9 }
            if buttons.contains("r1")       { flags |= 1 << 10 }
            if buttons.contains("l2")       { flags |= 1 << 11 }
            if buttons.contains("r2")       { flags |= 1 << 12 }
            if buttons.contains("dpad_up")  { flags |= 1 << 13 }
            if buttons.contains("dpad_down"){ flags |= 1 << 14 }
            if buttons.contains("dpad_left"){ flags |= 1 << 15 }
            if buttons.contains("dpad_right"){ flags |= 1 << 16 }

            gp.buttonFlags = flags
            gp.timestamp = UInt64(Date().timeIntervalSince1970 * 1_000)
        }
    }

    // MARK: - Response handling
    private func handleOpModeList(data: String) {
        if let jsonData = data.data(using: .utf8) {
            do {
                let decoded = try JSONDecoder().decode([OpModeData].self, from: jsonData)
                opModes = decoded
                self.logs.append("Received \(opModes.count) OpModes")
            } catch {
                self.logs.append("Failed to decode OpMode list: \(error.localizedDescription)")
            }
        }
    }

    private func handleRobotState(data: String) {
        if let intValue = Int8(data) {
            self.robotState = RobotOpModeState(rawValue: intValue) ?? .unknown
            self.logs.append("Robot state: \(robotState)")
        }
    }
    
    // Helper - TODO: move to different file sometime soon
    private func tryParseJSON(_ text: String) -> Any? {
        guard let data = text.data(using: .utf8) else { return nil }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return json
        } catch {
            print("[ProtocolEngine] ← JSON parse failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Supporting Models
struct Telemetry {
    var batteryVoltage: Double
    var status: String
}

struct Settings {
    var ipAddress: String
    var port: String
}

struct OpModeData: Codable, Hashable {
    var flavor: String
    var group: String
    var name: String
    var source: String?
    var systemOpModeDisplayName: String?
}
