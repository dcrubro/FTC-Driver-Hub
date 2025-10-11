//
//  RootView.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var controller: FTCController
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }
            GamepadView()
                .tabItem {
                    Label("Gamepad", systemImage: "gamecontroller")
                }
            TelemetryView()
                .tabItem {
                    Label("Telemetry", systemImage: "list.clipboard")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
