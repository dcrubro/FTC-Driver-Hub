import SwiftUI
import Combine

@MainActor
final class FTCController: ObservableObject {
    @Published var telemetry = Telemetry(batteryVoltage: 0)
    @Published var logs: [String] = []
    @Published var settings = Settings(ipAddress: "192.168.43.1", port: "20884")
    @Published var isConnected = false

    @Published var opModes: [String] = []
    @Published var selectedOpMode: String? = nil
    @Published var robotState: RobotOpModeState = .unknown

    private var engine: ProtocolEngine?

    func connect() {
        guard !isConnected else { return }
        logs.append("Connecting to \(settings.ipAddress):\(settings.port)...")

        let cfg = ProtocolEngine.Config(
            host: settings.ipAddress,
            port: UInt16(settings.port) ?? 20884,
            tickHz: 25.0,
            sendHeartbeat: true,
            sendGamepad: true
        )

        let engine = ProtocolEngine(config: cfg)

        // Telemetry updates
        engine.onTelemetry = { [weak self] telemetryPacket in
            guard let self else { return }

            var voltage: Double = 0
            for entry in telemetryPacket.floatEntries {
                if entry.key == "$Robot$Battery$Level$" {
                    voltage = Double(entry.value)
                }
            }
            self.telemetry = Telemetry(batteryVoltage: voltage)
        }

        // Command handling
        engine.onCommand = { [weak self] cmd in
            guard let self else { return }

            switch cmd.command {
            case "CMD_NOTIFY_OP_MODE_LIST":
                self.handleOpModeList(data: cmd.data)
            case "CMD_NOTIFY_ROBOT_STATE":
                self.handleRobotState(data: cmd.data)
            default:
                self.logs.append("Command received: \(cmd.command)")
            }
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
