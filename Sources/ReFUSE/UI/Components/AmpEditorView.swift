// AmpEditorView.swift
// Migrazione di amp_editor.ts

import SwiftUI

struct AmpEditorView: View {
    @Environment(FuseAPI.self) private var api
    
    // Convert array of models to identifiable for ForEach
    private var allAmpModels: [ModelDef] {
        AMP_MODELS.values.sorted { $0.name < $1.name }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 15)
    ]
    
    var body: some View {
        if let settings = api.amp.getSettings() {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Amplifier")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Picker("", selection: Binding(
                        get: { settings.modelId },
                        set: { newId in
                            Task { try? await api.amp.setAmpModelById(newId) }
                        }
                    )) {
                        ForEach(allAmpModels, id: \.id) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                    .frame(width: 200)
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Main Knobs Grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(settings.knobs, id: \.name) { knob in
                        KnobView(name: knob.name, value: knob.value) { newValue in
                            Task { try? await api.amp.setAmpKnob(index: knob.index, value: newValue) }
                        }
                    }
                }
                
                // Cabinet
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cabinet")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    
                    Picker("", selection: Binding(
                        get: { settings.cabinetId },
                        set: { newId in
                            Task { try? await api.amp.setCabinetById(newId) }
                        }
                    )) {
                        ForEach(CABINET_MODELS, id: \.id) { cab in
                            Text(cab.name).tag(cab.id)
                        }
                    }
                    .frame(maxWidth: 250)
                }
                
                // Advanced Parameters
                DisclosureGroup("Advanced parameters") {
                    LazyVGrid(columns: columns, spacing: 20) {
                        KnobView(name: "Bias", value: settings.bias) { v in setAdvanced(index: 10, value: v) }
                        KnobView(name: "Noise Gate", value: settings.noiseGate) { v in setAdvanced(index: 15, value: v) }
                        KnobView(name: "Gate Thresh", value: settings.threshold) { v in setAdvanced(index: 16, value: v) }
                        KnobView(name: "Sag", value: settings.sag) { v in setAdvanced(index: 19, value: v) }
                        KnobView(name: "Brightness", value: settings.brightness) { v in setAdvanced(index: 20, value: v) }
                        KnobView(name: "Depth", value: settings.depth) { v in setAdvanced(index: 9, value: v) }
                    }
                    .padding(.top, 10)
                }
                .foregroundColor(.gray)
                .padding(.top, 10)
            }
            .padding()
            .background(Color(white: 0.17))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.3), radius: 6)
            .padding()
        }
    }
    
    private func setAdvanced(index: Int, value: Int) {
        Task {
            try? await api.amp.setAmpKnob(index: index, value: value)
        }
    }
}
