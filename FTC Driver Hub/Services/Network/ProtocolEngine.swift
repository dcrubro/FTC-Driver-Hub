//
//  ProtocolEngine.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import Foundation
import Combine

enum HandshakeState: String {
    case idle
    case requesting
    case awaitingResponse
    case complete
}

@MainActor
final class ProtocolEngine: ObservableObject {
    struct Config {
        var host: String
        var port: UInt16 = 20884
        var tickHz: Double = 25.0
        var heartbeatHz: Double = 1.0
        var sendHeartbeat: Bool = true
        var sendGamepad: Bool = true
    }

    // MARK: - Public Surface
    @Published private(set) var isRunning = false
    @Published private(set) var awaitingRobotState = true
    @Published private(set) var handshakeState: HandshakeState = .idle
    @Published private(set) var isReady = false
    private var handshakeTimer: DispatchSourceTimer?
    private var hasReceivedRobotState = false
    var onTelemetry: ((TelemetryPacket) -> Void)?
    var onCommand: ((CommandPacket) -> Void)?
    var onHeartbeat: ((HeartbeatPacket) -> Void)?

    private var udp = UDPClient()
    private var timers: [DispatchSourceTimer] = []
    private var config: Config
    private var sequenceNumber: Int16 = Int16.random(in: 1000...3000)
    private var hasPerformedHandshake = false

    var latestGamepad: GamepadPacket?
    var currentOpModeState: RobotOpModeState = .unknown
    var sdkBuildMonth: Int8 = 8
    var sdkBuildYear: Int16 = 2025
    var sdkMajor: Int8 = 11
    var sdkMinor: Int8 = 0

    init(config: Config) {
        self.config = config
    }
    
    private func nextSequenceNumber() -> Int16 {
        sequenceNumber &+= 1
        return sequenceNumber
    }

    // MARK: - Lifecycle
    func start() {
        guard !isRunning else { return }
        isRunning = true

        udp.onReceive = { [weak self] data, _ in
            Task { @MainActor in self?.handleInbound(data) }
        }

        udp.start(host: config.host, port: config.port)
        print("UDP socket ready on \(config.host):\(config.port)")

        //beginHandshake()
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

        if config.sendHeartbeat {
            timer(every: 1.0 / config.heartbeatHz) { [weak self] in
                Task { @MainActor in self?.sendHeartbeat() }
            }
        }
        
        if config.sendGamepad {
            //print("yahr")
            timer(every: 1.0 / config.tickHz) { [weak self] in
                Task { @MainActor in self?.sendGamepad() }
            }
        }
    }

    // MARK: - Send Packets
    private func sendGamepad() {
        // If we don't have a gamepad or it's stale, send idle
        guard let gp = latestGamepad else {
            udp.send(PacketEnvelope(
                type: PacketType.gamepad.rawValue,
                sequenceNumber: nextSequenceNumber(),
                payload: GamepadPacket.idle().encode()
            ).encode())
            return
        }

        // Detect if the packet is "all zero" (i.e. idle)
        if gp.isIdle {
            udp.send(PacketEnvelope(
                type: PacketType.gamepad.rawValue,
                sequenceNumber: nextSequenceNumber(),
                payload: gp.encode()
            ).encode())
            return
        }

        // Otherwise send the latest input packet
        let envelope = PacketEnvelope(
            type: PacketType.gamepad.rawValue,
            sequenceNumber: nextSequenceNumber(),
            payload: gp.encode()
        )
        udp.send(envelope.encode())
    }

    private func sendTimeInit() {
        let now = Date()
        let time = now.timeIntervalSince1970
        let nanos = UInt64(time * 1_000_000_000.0)
        let millis = UInt64(time * 1_000.0)

        let packet = TimePacket(
            timestamp: nanos,
            robotOpModeState: RobotOpModeState.notStarted, // requesting state
            unixMillisSent: millis,
            unixMillisReceived1: 0,
            unixMillisReceived2: 0,
            timezone: TimeZone.current.identifier
        )
        
        let envelope = PacketEnvelope(
            type: PacketType.time.rawValue, sequenceNumber: nextSequenceNumber(), payload: packet.encode()
        )

        udp.send(envelope.encode())
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
        
        let envelope = PacketEnvelope(
            type: PacketType.heartbeat.rawValue, sequenceNumber: nil, payload: hb.encode()
        )
        
        udp.send(envelope.encode())
        
        if !isReady { isReady = true }
    }
    
    @MainActor
    private func sendHandshakeWave() {
        guard handshakeState == .requesting else { return }

        //sendCommand(name: "CMD_REQUEST_OP_MODE_LIST")
        sendCommand(name: "CMD_REQUEST_ACTIVE_CONFIG")
        sendCommand(name: "CMD_INIT_OP_MODE", data: "$Stop$Robot$")
        //DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
        sendTimeInit()
        sendTimeInit()

        print("[ProtocolEngine] → Handshake wave sent")
    }

    func beginHandshake() {
        guard handshakeState == .idle else { return }
        handshakeState = .requesting
        hasReceivedRobotState = false

        print("[ProtocolEngine] Starting handshake with \(config.host):\(config.port)")

        // Timer that fires every 250 ms until we get a robot state
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now(), repeating: 0.25)
        timer.setEventHandler { [weak self] in
            Task { @MainActor in self?.sendHandshakeWave() }
        }
        timer.resume()
        handshakeTimer = timer
    }
    
    func sendCommand(name: String, data: String = "", acknowledged: Bool = false) {
        let nanos = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
        let cmd = CommandPacket(
            timestamp: nanos,
            acknowledged: acknowledged,
            command: name,
            data: data
        )

        // Wrap payload into PacketEnvelope
        let envelope = PacketEnvelope(
            type: PacketType.command.rawValue, // Command packet
            sequenceNumber: nextSequenceNumber(),
            payload: cmd.encode()
        )

        udp.send(envelope.encode())
    }
    
    private func sendAck(for cmd: CommandPacket, seq: Int16) {
        //let nanos = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
        let ack = CommandPacket(
            timestamp: cmd.timestamp,
            acknowledged: true,
            command: cmd.command,
            data: ""
        )

        let envelope = PacketEnvelope(
            type: PacketType.command.rawValue,
            sequenceNumber: seq,
            payload: ack.encode()
        )
        udp.send(envelope.encode())
    }
    
    @MainActor
    private func handleCommandPacket(_ cmd: CommandPacket, seq: Int16?) {
        print("[ProtocolEngine] ← Incoming Command: \(cmd.command) data=\(cmd.data) ack=\(cmd.acknowledged)")
        
        onCommand?(cmd)
        
        // Always ACK any incoming command from the RC
        guard !cmd.acknowledged else { return }
        
        sendAck(for: cmd, seq: seq ?? 0)
        print("[ProtocolEngine] ← Acknowledged Command: seq=\(seq ?? -1)")
    }

    // MARK: - Inbound handling
    private func handleInbound(_ raw: Data) {
        guard let routed = PacketRouter.decode(raw) else { return }

        switch routed.payload {
        case let cmd as CommandPacket:
            handleCommandPacket(cmd, seq: routed.sequenceNumber)

        case let telemetry as TelemetryPacket:
            onTelemetry?(telemetry)

        case let hb as HeartbeatPacket:
            print("[ProtocolEngine] ← Heartbeat packet: \(hb)")

        case let time as TimePacket:
            print("[ProtocolEngine] ← Time packet: \(time)")

        default:
            print("[ProtocolEngine] ⚠️ Unhandled packet type \(routed.type)")
        }
    }

    // MARK: - Gamepad Update Utility
    func updateGamepad(_ builder: (inout GamepadPacket) -> Void) {
        var gp = latestGamepad ?? GamepadPacket.idle()
        builder(&gp)

        // Apply dead-zone correction
        func dz(_ v: Float) -> Float { abs(v) < 0.05 ? 0 : v }
        gp.leftStickX = dz(gp.leftStickX)
        gp.leftStickY = dz(gp.leftStickY)
        gp.rightStickX = dz(gp.rightStickX)
        gp.rightStickY = dz(gp.rightStickY)

        gp.timestamp = UInt64(Date().timeIntervalSince1970 * 1_000)
        latestGamepad = gp
    }
}
