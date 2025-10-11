//
//  TelemetryView.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import SwiftUI
import Combine

struct TelemetryView: View {
    @EnvironmentObject var controller: FTCController
    @State private var timer: AnyCancellable?
    
    private let refreshInterval: TimeInterval = 0.25

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Telemetry")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 10)

                    if controller.isConnected {
                        if controller.latestTelemetry.isEmpty {
                            Text("No telemetry received yet.")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(controller.latestTelemetry.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack {
                                        Text(key)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(value)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                    Divider()
                                }
                            }
                        }
                    } else {
                        VStack {
                            Spacer()
                            Text("Disconnected")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .frame(width: geo.size.width, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground)) // Adapts to theme
            .foregroundStyle(Color.primary) // Matches system text color
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear { startRefreshLoop() }
        .onDisappear { timer?.cancel() }
    }

    // MARK: - Refresh
    private func startRefreshLoop() {
        timer?.cancel()
        timer = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in refreshTelemetry() }
    }

    private func refreshTelemetry() {
        guard controller.isConnected else { return }
        controller.objectWillChange.send()
    }
}
