// PresetSidebarView.swift
// Migrazione di sidebar.ts

import SwiftUI

struct PresetSidebarView: View {
    @Environment(FuseAPI.self) private var api
    @Environment(AppState.self) private var state
    @State private var saveNameInput: String = ""
    @State private var showingSaveAlert = false
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ReFUSE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                Spacer()
                Button {
                    Task { await api.disconnect() }
                } label: {
                    Label("Disconnect", systemImage: "eject.fill")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Disconnect amp")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Preset list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(0..<24, id: \.self) { slot in
                        presetRow(slot: slot)
                    }
                }
                .padding(8)
            }

            Divider()

            // Preset controls
            HStack(spacing: 8) {
                Button {
                    guard let slot = state.currentPresetSlot else { return }
                    saveNameInput = state.presets[slot]?.name ?? ""
                    showingSaveAlert = true
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .disabled(state.currentPresetSlot == nil)

                // Import preset from file
                Button {
                    importPreset()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
        }
        .frame(minWidth: 200, idealWidth: 220)
        .alert("Save Preset", isPresented: $showingSaveAlert) {
            TextField("Preset name", text: $saveNameInput)
            Button("Save") {
                guard let slot = state.currentPresetSlot else { return }
                Task { try? await api.presets.savePreset(slot: slot, name: saveNameInput) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func presetRow(slot: Int) -> some View {
        let isActive = state.currentPresetSlot == slot
        let name = state.presets[slot]?.name ?? "Preset \(slot + 1)"

        return Button {
            Task { try? await api.presets.loadPreset(slot: slot) }
        } label: {
            HStack(spacing: 8) {
                Text(String(format: "%02d", slot + 1))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(isActive ? .orange : .secondary)
                    .frame(width: 24, alignment: .trailing)

                Text(name)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if isActive {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isActive ? Color.orange.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func importPreset() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml]
        panel.title = "Import FUSE Preset"
        if panel.runModal() == .OK, let url = panel.url {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                Task { try? await api.presets.loadXml(content) }
            }
        }
    }
}
