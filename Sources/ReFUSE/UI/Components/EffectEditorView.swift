// EffectEditorView.swift
// Migrazione di effect_editor.ts

import SwiftUI

struct EffectEditorView: View {
    @Environment(FuseAPI.self) private var api
    let activeSlot: Int
    
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 15)
    ]
    
    private func models(for type: DspType) -> [ModelDef] {
        EFFECT_MODELS.values.filter { $0.type == type }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        let effect = api.effects.getSettings(slot: activeSlot)
        
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Slot \(activeSlot + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("", selection: Binding(
                    get: { effect?.modelId ?? 0 },
                    set: { newId in
                        Task { try? await api.effects.setEffectById(slot: activeSlot, modelId: newId) }
                    }
                )) {
                    Text("-- Empty --").tag(0)
                    
                    Section(header: Text("Stompbox")) {
                        ForEach(models(for: .stomp), id: \.id) { m in Text(m.name).tag(m.id) }
                    }
                    Section(header: Text("Modulation")) {
                        ForEach(models(for: .mod), id: \.id) { m in Text(m.name).tag(m.id) }
                    }
                    Section(header: Text("Delay")) {
                        ForEach(models(for: .delay), id: \.id) { m in Text(m.name).tag(m.id) }
                    }
                    Section(header: Text("Reverb")) {
                        ForEach(models(for: .reverb), id: \.id) { m in Text(m.name).tag(m.id) }
                    }
                }
                .frame(width: 200)
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            if let e = effect {
                HStack(spacing: 20) {
                    Toggle(isOn: Binding(
                        get: { e.enabled },
                        set: { val in Task { try? await api.effects.setEffectEnabled(slot: activeSlot, enabled: val) } }
                    )) {
                        Text(e.enabled ? "Active" : "Bypassed")
                            .foregroundColor(e.enabled ? .white : .gray)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    Text(String(format: "Type: 0x%02X", e.type.rawValue))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(e.knobs, id: \.index) { knob in
                        KnobView(name: knob.name, value: knob.value) { newValue in
                            Task { try? await api.effects.setEffectKnob(slot: activeSlot, index: knob.index, value: newValue) }
                        }
                    }
                }
                .padding(.top, 10)
                
            } else {
                VStack(spacing: 12) {
                    Text("Select an effect model above to assign to this slot.")
                    Text("Note, an effect can only be assigned to one slot at a time.")
                }
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding()
        .background(Color(white: 0.17))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.3), radius: 6)
        .padding()
    }
}
