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
                        }

                        Picker("OpMode", selection: $controller.selectedOpMode) {
                            ForEach(controller.opModes, id: \.self) { opmode in
                                Text(opmode).tag(Optional(opmode))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(controller.logs.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Driver Hub Dashboard")
        }
    }
}
