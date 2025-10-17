import SwiftUI
import Combine

@MainActor
final class FTCController: ObservableObject {
    @Published var telemetry = Telemetry(batteryVoltage: 0, status: "Null")
    @Published var logs: [String] = []
    @Published var settings = Settings(ipAddress: "192.168.43.1", port: "20884")
    @Published var isConnected = false

    @Published var opModes: [String] = []
    @Published var selectedOpMode: String? = nil
    @Published var robotState: RobotOpModeState = .unknown
    @Published var latestTelemetry: [String: String] = [:]

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

            for entry in packet.stringEntries {
                if entry.key == "$Robot$Battery$Level$",
                   let voltage = Double(entry.value) {
                    DispatchQueue.main.async {
                        self.telemetry.batteryVoltage = voltage
                    }
                    self.logs.append("Robot Battery: \(voltage)V")
                    print("Robot Battery: \(voltage)V")
                }

                if entry.key == "Status" {
                    DispatchQueue.main.async {
                        self.telemetry.status = entry.value
                    }
                }
            }
        }

        // MARK: - Command handling
        engine.onCommand = { [weak self] (cmd: CommandPacket) in
            guard let self else { return }

            switch cmd.command {
            case "CMD_NOTIFY_OP_MODE_LIST":
                self.logs.append("Received OpMode list.")
            case "CMD_NOTIFY_ROBOT_STATE":
                self.logs.append("Robot state update: \(cmd.data)")
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
        sendCommand("CMD_INIT_OP_MODE", data: opMode)
        logs.append("Init OpMode: \(opMode)")
    }

    func startOpMode() {
        guard let opMode = selectedOpMode else { return }
        sendCommand("CMD_RUN_OP_MODE", data: opMode)
        logs.append("Start OpMode: \(opMode)")
    }

    func stopOpMode() {
        sendCommand("CMD_INIT_OP_MODE", data: "$Stop$Robot$")
        logs.append("Stop OpMode")
    }
    
    // MARK: - Update Gamepad
    func updateGamepad(leftX: Double, leftY: Double, rightX: Double, rightY: Double, buttons: Set<String>) {
        guard let engine else { return }

        engine.updateGamepad { gp in
            gp.leftStickX = Float(leftX)
            gp.leftStickY = Float(leftY)
            gp.rightStickX = Float(rightX)
            gp.rightStickY = Float(rightY)

            // Map button names to flags (simplified)
            var flags: UInt32 = 0
            if buttons.contains("triangle") { flags |= 1 << 5 }
            if buttons.contains("square")   { flags |= 1 << 6 }
            if buttons.contains("circle")   { flags |= 1 << 7 }
            if buttons.contains("cross")    { flags |= 1 << 8 }

            gp.buttonFlags = flags
            gp.timestamp = UInt64(Date().timeIntervalSince1970 * 1_000)
        }
    }

    // MARK: - Response handling
    private func handleOpModeList(data: String) {
        if let jsonData = data.data(using: .utf8) {
            do {
                let decoded = try JSONDecoder().decode([OpModeData].self, from: jsonData)
                self.opModes = decoded.map { $0.name }
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

struct OpModeData: Codable {
    var flavor: String
    var group: String
    var name: String
    var source: String?
    var systemOpModeDisplayName: String?
}
