//
//  FTC_Driver_HubApp.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import SwiftUI

@main
struct FTC_Driver_HubApp: App {
    @StateObject private var engine = ProtocolEngine(
        config: .init(host: "192.168.43.1")
    )
    
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(engine)
        }
    }
}
