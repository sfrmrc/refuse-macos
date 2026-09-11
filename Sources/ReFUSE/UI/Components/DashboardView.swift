// DashboardView.swift
// Migrazione di dashboard.ts — contiene SignalChain e l'editor attivo (Amp o Effect)

import SwiftUI

struct DashboardView: View {
    @State private var activeSlot: ActiveSlot? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Top: Signal Chain
            SignalChainView(activeSlot: $activeSlot)
            
            // Bottom: Editor
            ScrollView {
                VStack {
                    switch activeSlot {
                    case .amp:
                        AmpEditorView()
                    case .effect(let slot):
                        EffectEditorView(activeSlot: slot)
                    case nil:
                        VStack(spacing: 12) {
                            Text("Select an item in the signal chain to edit its settings.")
                                .font(.body)
                                .italic()
                                .foregroundColor(Color.gray)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(white: 0.12))
        }
    }
}
