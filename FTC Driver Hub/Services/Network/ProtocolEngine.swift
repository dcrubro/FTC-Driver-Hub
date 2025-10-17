//
//  ProtocolEngine.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation
import Combine

@MainActor
final class ProtocolEngine: ObservableObject {
    struct Config {
        var host: String
        var port: UInt16 = 20884
        var tickHz: Double = 25.0
        var heartbeatHz: Double = 10.0
        var sendHeartbeat: Bool = true
        var sendGamepad: Bool = true
    }

    // MARK: - Public Surface
    @Published private(set) var isRunning = false
    var onTelemetry: ((TelemetryPacket) -> Void)?
    var onCommand: ((CommandPacket) -> Void)?
    var onHeartbeat: ((HeartbeatPacket) -> Void)?

    private var udp = UDPClient()
    private var timers: [DispatchSourceTimer] = []
    private var config: Config

    var latestGamepad: GamepadPacket?
    var currentOpModeState: RobotOpModeState = .unknown
    var sdkBuildMonth: Int8 = 9
    var sdkBuildYear: Int16 = 2023
    var sdkMajor: Int8 = 8
    var sdkMinor: Int8 = 1

    init(config: Config) {
        self.config = config
    }

    // MARK: - Lifecycle
    func start() {
        guard !isRunning else { return }
        isRunning = true

        udp.onReceive = { [weak self] data, _ in
            Task { @MainActor in
                self?.handleInbound(data)
            }
        }
        udp.start(host: config.host, port: config.port)

        sendTimeInit()
        schedulePackets()
    }

    func stop() {
        timers.forEach { $0.cancel() }
        timers.removeAll()
        udp.stop()
        isRunning = false
    }

    // MARK: - Packet Scheduling
    private func schedulePackets() {
        func timer(every seconds: Double, _ block: @escaping () -> Void) {
            let t = DispatchSource.makeTimerSource(queue: .global())
            t.schedule(deadline: .now(), repeating: seconds)
            t.setEventHandler(handler: block)
            t.resume()
            timers.append(t)
        }

        if config.sendGamepad {
            timer(every: 1.0 / config.tickHz) { [weak self] in
                Task { @MainActor in self?.sendGamepad() }
            }
        }
        if config.sendHeartbeat {
            timer(every: 1.0 / config.heartbeatHz) { [weak self] in
                Task { @MainActor in self?.sendHeartbeat() }
            }
        }
    }

    // MARK: - Send Packets
    private func sendGamepad() {
        guard let gp = latestGamepad else { return }
        udp.send(gp.encode())
    }

    private func sendTimeInit() {
        let now = Date()
        let nanos = UInt64(now.timeIntervalSince1970 * 1_000_000_000.0)
        let millis = UInt64(now.timeIntervalSince1970 * 1_000.0)
        let pkt = TimePacket(
            timestamp: nanos,
            robotState: currentOpModeState,
            unixMillisSent: millis,
            unixMillisReceived1: 0,
            unixMillisReceived2: 0,
            timezone: TimeZone.current.identifier
        )
        udp.send(pkt.encode())
    }

    private func sendHeartbeat() {
        let hb = HeartbeatPacket(
            peerType: 1,
            token: 10003,
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

    // MARK: - Inbound handling
    private func handleInbound(_ raw: Data) {
        guard let envelope = PacketRouter.decode(raw) else { return }

        switch envelope {
        case .telemetry(let t): onTelemetry?(t)
        case .command(let c): onCommand?(c)
        case .heartbeat(let hb): onHeartbeat?(hb)
        default: break
        }
    }

    // MARK: - Gamepad Update Utility
    func updateGamepad(_ builder: (inout GamepadPacket) -> Void) {
        var gp = latestGamepad ?? GamepadPacket(
            gamepadID: 2002,
            timestamp: 0,
            leftStickX: 0, leftStickY: 0,
            rightStickX: 0, rightStickY: 0,
            leftTrigger: 0, rightTrigger: 0,
            buttonFlags: 0,
            user: 1,
            legacyType: 2,
            gamepadType: 2,
            touch1X: 0, touch1Y: 0,
            touch2X: 0, touch2Y: 0
        )
        gp.timestamp = UInt64(Date().timeIntervalSince1970 * 1_000.0)
        builder(&gp)
        latestGamepad = gp
    }
}
