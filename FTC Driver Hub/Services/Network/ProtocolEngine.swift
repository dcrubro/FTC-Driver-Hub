//
//  ProtocolEngine.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation
import Combine
import Network

@MainActor
final class ProtocolEngine: ObservableObject {

    // MARK: Configuration
    struct Config {
        var host: String
        var port: UInt16 = 20884
        /// 25Hz tick matches original comment for Gamepad & Heartbeat
        var tickHz: Double = 25.0
        var heartbeatHZ: Double = 10.0
        /// Whether to send heartbeat on each tick
        var sendHeartbeat: Bool = true
        /// Whether to send gamepad on each tick
        var sendGamepad: Bool = true
    }

    // MARK: Public surface
    @Published private(set) var isRunning: Bool = false
    var onTelemetry: ((TelemetryPacket) -> Void)?
    var onCommand: ((CommandPacket) -> Void)?

    // You can set these from your UI/view model
    var latestGamepad: GamepadPacket?
    var currentOpModeState: RobotOpModeState = .unknown
    var sdkBuildMonth: Int8 = 9
    var sdkBuildYear: Int16 = 2023
    var sdkMajor: Int8 = 8
    var sdkMinor: Int8 = 1

    // MARK: Internals
    private var config: Config
    private let udp = UDPClient()
    private var tickTimer: DispatchSourceTimer?
    
    private var gamepadTimer: DispatchSourceTimer?
    private var heartbeatTimer: DispatchSourceTimer?

    init(config: Config) {
        self.config = config
        udp.onReceive = { [weak self] raw in
            Task { @MainActor in
                self?.handleInbound(raw)
            }
        }
    }

    // MARK: Lifecycle
    func start() {
        guard !isRunning else { return }
        isRunning = true
        udp.start(host: config.host, port: config.port)
        sendTimeInit()

        // Gamepad timer — 25 Hz
        let gpTimer = DispatchSource.makeTimerSource(queue: .global())
        gpTimer.schedule(deadline: .now(), repeating: 1.0 / 25.0)
        gpTimer.setEventHandler { [weak self] in
            Task { @MainActor in self?.tickGamepad() }
        }
        gpTimer.resume()
        gamepadTimer = gpTimer

        // Heartbeat timer — 10 Hz
        let hbTimer = DispatchSource.makeTimerSource(queue: .global())
        hbTimer.schedule(deadline: .now(), repeating: 1.0 / 10.0)
        hbTimer.setEventHandler { [weak self] in
            Task { @MainActor in self?.sendHeartbeat() }
        }
        hbTimer.resume()
        heartbeatTimer = hbTimer
    }

    func stop() {
        gamepadTimer?.cancel()
        heartbeatTimer?.cancel()
        gamepadTimer = nil
        heartbeatTimer = nil
        udp.stop()
        isRunning = false
    }

    // MARK: Tick loop
    private func tickGamepad() {
        if let gp = latestGamepad {
            udp.send(gp.encode())
        }
    }

    // MARK: Outbound helpers

    private func sendTimeInit() {
        let now = Date()
        let nanos = UInt64(now.timeIntervalSince1970 * 1_000_000_000.0)
        let millis = UInt64(now.timeIntervalSince1970 * 1_000.0)

        let packet = TimePacket(
            timestamp: nanos,
            robotOpModeState: currentOpModeState,
            unixMillisSent: millis,
            unixMillisReceived1: 0,
            unixMillisReceived2: 0,
            timezone: TimeZone.current.identifier
        )
        udp.send(packet.encode())
    }

    private func sendHeartbeat() {
        let hb = HeartbeatPacket(
            peerType: 1, // PEER_TYPE_PEER
            sequenceNumber: 10003, // request
            sdkBuildMonth: sdkBuildMonth,
            sdkBuildYear: sdkBuildYear,
            sdkMajorVersion: sdkMajor,
            sdkMinorVersion: sdkMinor
        )
        udp.send(hb.encode())
    }

    func sendCommand(name: String, data: String = "", acknowledged: Bool = false) {
        let nanos = UInt64(Date().timeIntervalSince1970 * 1_000_000_000.0)
        let cmd = CommandPacket(
            timestamp: nanos,
            acknowledged: acknowledged,
            command: name,
            data: data
        )
        udp.send(cmd.encode())
    }

    // MARK: Inbound
    private func handleInbound(_ raw: Data) {
        guard let envelope = PacketRouter.decode(raw) else { return }

        switch envelope {
        case .telemetry(let t):
            onTelemetry?(t)
        case .command(let c):
            onCommand?(c)
        case .time, .gamepad, .heartbeat:
            // Usually not received by Driver Hub, but safe to ignore/log if they appear.
            break
        }
    }

    // MARK: Utilities (for convenience from UI)
    func updateGamepad(_ builder: (inout GamepadPacket) -> Void) {
        var gp = latestGamepad ?? GamepadPacket(
            gamepadID: 2002,
            timestamp: 0,
            leftStickX: 0, leftStickY: 0,
            rightStickX: 0, rightStickY: 0,
            leftTrigger: 0, rightTrigger: 0,
            buttonFlags: 0,
            user: 1,
            legacyType: 2, gamepadType: 2,
            touchpadFinger1X: 0, touchpadFinger1Y: 0,
            touchpadFinger2X: 0, touchpadFinger2Y: 0
        )
        // Update timestamp (millis) each frame; adjust if your Rust uses another unit.
        gp.timestamp = UInt64(Date().timeIntervalSince1970 * 1_000.0)
        builder(&gp)
        latestGamepad = gp
    }
}
