// ReFUSEApp.swift — @main entry point

import SwiftUI

@main
struct ReFUSEApp: App {
    @State private var api = FuseAPI()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(api)
                .environment(api.state)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
