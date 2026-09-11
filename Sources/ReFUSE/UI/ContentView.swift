// ContentView.swift
// Migrazione di root.ts — root view con routing connected/disconnected

import SwiftUI

struct ContentView: View {
    @Environment(FuseAPI.self) private var api
    @Environment(AppState.self) private var state

    var body: some View {
        Group {
            if state.connected {
                NavigationSplitView {
                    PresetSidebarView()
                } detail: {
                    DashboardView()
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                WelcomeView()
                    .frame(minWidth: 700, minHeight: 480)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.connected)
    }
}
