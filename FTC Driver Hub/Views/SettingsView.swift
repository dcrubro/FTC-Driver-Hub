//
//  SettingsView.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var controller: FTCController
    @AppStorage("ipAddress") private var ipAddress: String = "192.168.43.1"
    @AppStorage("port") private var port: String = "20884"

    @State private var portIsInvalid = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - App Settings
                Section(header: Text("App Settings")) {
                    HStack {
                        Label("IP Address", systemImage: "network")
                        Spacer()
                        TextField("192.168.43.1", text: $ipAddress)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit { updateConnectionSettings() }
                    }

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Label("Port", systemImage: "number")
                            Spacer()
                            TextField("20884", text: $port)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onSubmit { updateConnectionSettings() }
                                .onChange(of: port) { _ in
                                    portIsInvalid = UInt16(port) == nil
                                }
                        }
                        if portIsInvalid {
                            Text("Invalid port (must be 1–65535)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Section(header: Text("Controller")) {
                    HStack {
                        Text("Bluetooth Gamepad")
                        Spacer()
                        Text(controller.controllerName)
                            .foregroundColor(controller.controllerName == "None" ? .secondary : .green)
                    }
                }

                // MARK: - Control Hub Settings
                Section(header: Text("Control Hub Settings"),
                        footer: Text("Control Hub options will appear here in a future update.")) {
                    Text("No settings available yet.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { updateConnectionSettings() }
        }
    }

    // MARK: - Update function
    private func updateConnectionSettings() {
        controller.settings.ipAddress = ipAddress
        guard UInt16(port) != nil else {
            portIsInvalid = true
            return
        }
        portIsInvalid = false
        controller.settings.port = port
    }
}
