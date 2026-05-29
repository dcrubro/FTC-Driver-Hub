//
//  DashboardView.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var controller: FTCController

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                // MARK: Connection Controls
                HStack(spacing: 12) {
                    Button(action: {
                        controller.isConnected ? controller.disconnect() : controller.connect()
                    }) {
                        Label(
                            controller.isConnected ? "Disconnect" : "Connect",
                            systemImage: controller.isConnected ? "wifi.slash" : "wifi"
                        )
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(controller.isConnected ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                        .cornerRadius(12)
                    }

                    Spacer()
                    Text(controller.isConnected ? "Connected" : "Disconnected")
                        .foregroundColor(controller.isConnected ? .green : .secondary)
                }
                .padding(.horizontal)

                Divider()

                // MARK: Telemetry
                VStack(alignment: .leading, spacing: 8) {
                    Text("Telemetry")
                        .font(.title3).bold()
                    HStack {
                        Label("Battery", systemImage: "bolt.fill")
                            .frame(width: 90, alignment: .leading)
                        Text(String(format: "%.1f V", controller.telemetry.batteryVoltage))
                            .font(.system(.title3, design: .monospaced))
                        if controller.telemetry.batteryVoltage > 0 && controller.telemetry.batteryVoltage < 11.5 {
                            Label("Low Battery", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption).bold()
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // MARK: OpMode Selection & Controls
                if controller.isConnected {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Select OpMode")
                                .font(.headline)
                            Spacer()
                            RobotStateBadge(state: controller.robotState)
                        }

                        Picker("Select OpMode", selection: $controller.selectedOpMode) {
                            ForEach(controller.opModes, id: \.name) { opmode in
                                Text(opmode.systemOpModeDisplayName ?? opmode.name)
                                    .tag(Optional(opmode.name))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                        HStack {
                            Button("Init") {
                                controller.initOpMode()
                            }
                            .disabled(controller.selectedOpMode == nil ||
                                      controller.robotState == .initialized ||
                                      controller.robotState == .running)

                            Button("Start") {
                                controller.startOpMode()
                            }
                            .disabled(controller.robotState != .initialized)

                            Button("Stop") {
                                controller.stopOpMode()
                            }
                            .disabled(controller.robotState != .running)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                Divider()

                // MARK: Logs
                HStack {
                    Text("Logs")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        controller.clearLogs()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(controller.logs.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(6)
                                    .id("log-\(index)")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: controller.logs.count) { count in
                        if count > 0 {
                            withAnimation {
                                proxy.scrollTo("log-\(count - 1)", anchor: .bottom)
                            }
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Driver Hub Dashboard")
            .alert("Control Hub Error",
                isPresented: $controller.showErrorAlert,
                actions: {
                    Button("Dismiss", role: .cancel) { }
                },
                message: {
                    Text(controller.lastErrorMessage ?? "Unknown error from Control Hub.")
                }
            )
        }
    }
}

// MARK: - Robot State Badge
struct RobotStateBadge: View {
    var state: RobotOpModeState

    var body: some View {
        Text(label)
            .font(.caption).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private var label: String {
        switch state {
        case .unknown:          return "Unknown"
        case .notStarted:       return "Not Started"
        case .initialized:      return "Initialized"
        case .running:          return "Running"
        case .stopped:          return "Stopped"
        case .emergencyStopped: return "E-Stop"
        }
    }

    private var color: Color {
        switch state {
        case .unknown, .notStarted: return .secondary
        case .initialized:          return .yellow
        case .running:              return .green
        case .stopped:              return .orange
        case .emergencyStopped:     return .red
        }
    }
}
