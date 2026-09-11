// SignalChainView.swift
// Migrazione di signal_chain.ts — rappresentazione visiva della catena del segnale con drag and drop

import SwiftUI

enum ActiveSlot: Equatable {
    case amp
    case effect(Int)
}

struct SignalChainView: View {
    @Environment(FuseAPI.self) private var api
    @Binding var activeSlot: ActiveSlot?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Pre-Amp (slots 0...3)
                ForEach(0..<4, id: \.self) { i in
                    SlotView(slotIndex: i, activeSlot: $activeSlot)
                }
                
                // Amplifier
                AmpSlotView(activeSlot: $activeSlot)
                
                // Post-Amp (slots 4...7)
                ForEach(4..<8, id: \.self) { i in
                    SlotView(slotIndex: i, activeSlot: $activeSlot)
                }
            }
            .padding()
            .frame(minWidth: 424, minHeight: 110)
        }
        .background(Color(white: 0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(white: 0.2)),
            alignment: .bottom
        )
    }
}

// MARK: - Slot View

struct SlotView: View {
    @Environment(FuseAPI.self) private var api
    let slotIndex: Int
    @Binding var activeSlot: ActiveSlot?
    
    @State private var isTargeted = false
    
    var body: some View {
        let effect = api.effects.getSettings(slot: slotIndex)
        let isActive = activeSlot == .effect(slotIndex)
        let isEmpty = effect == nil
        
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(red: 44/255, green: 62/255, blue: 80/255) : Color(white: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isActive ? Color.blue : (isTargeted ? Color.green : Color(white: 0.2)), style: StrokeStyle(lineWidth: 2, dash: isEmpty ? [5] : []))
                )
                .shadow(color: isActive ? Color.blue.opacity(0.3) : .clear, radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let e = effect {
                        Text(familyLabel(for: e.type))
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(familyColor(for: e.type))
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                    Spacer()
                    Text("\(slotIndex + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.gray)
                }
                
                if let e = effect {
                    Text(e.model)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Text(e.enabled ? "●" : "○")
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray)
                } else {
                    Spacer()
                    Text("Empty")
                        .font(.system(size: 12, weight: .regular))
                        .italic()
                        .foregroundColor(Color(white: 0.33))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                }
            }
            .padding(8)
        }
        .frame(width: 100, height: 100)
        .onTapGesture {
            activeSlot = .effect(slotIndex)
        }
        .onDrag {
            NSItemProvider(object: String(slotIndex) as NSString)
        }
        .onDrop(of: [.plainText], isTargeted: $isTargeted) { providers in
            providers.first?.loadObject(ofClass: NSString.self) { string, error in
                if let str = string as? String, let fromSlot = Int(str), fromSlot != slotIndex {
                    Task {
                        // Optimistic UI update
                        DispatchQueue.main.async {
                            activeSlot = .effect(slotIndex)
                        }
                        try? await api.effects.moveEffect(fromSlot: fromSlot, toSlot: slotIndex)
                    }
                }
            }
            return true
        }
    }
    
    private func familyLabel(for type: DspType) -> String {
        switch type {
        case .stomp: return "STOMP"
        case .mod: return "MOD"
        case .delay: return "DELAY"
        case .reverb: return "REVERB"
        default: return "?"
        }
    }
    
    private func familyColor(for type: DspType) -> Color {
        switch type {
        case .stomp: return Color(red: 231/255, green: 76/255, blue: 60/255)
        case .mod: return Color(red: 52/255, green: 152/255, blue: 219/255)
        case .delay: return Color(red: 241/255, green: 196/255, blue: 15/255)
        case .reverb: return Color(red: 46/255, green: 204/255, blue: 113/255)
        default: return Color(white: 0.26)
        }
    }
}

// MARK: - Amp Slot View

struct AmpSlotView: View {
    @Environment(FuseAPI.self) private var api
    @Binding var activeSlot: ActiveSlot?
    
    var body: some View {
        let settings = api.amp.getSettings()
        let isActive = activeSlot == .amp
        
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(red: 93/255, green: 64/255, blue: 55/255) : Color(white: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isActive ? Color.orange : Color(white: 0.33), lineWidth: 2)
                )
                .shadow(color: isActive ? Color.orange.opacity(0.4) : .clear, radius: 5)
            
            VStack(spacing: 4) {
                if let s = settings {
                    Text("AMP")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(s.model)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    let cabName = cabinetById(s.cabinetId)?.name ?? "Cab \(s.cabinetId)"
                    Text(cabName)
                        .font(.system(size: 10))
                        .foregroundColor(Color.gray)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("AMP")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.gray)
                        .kerning(1)
                    Text("⚡")
                        .font(.system(size: 32))
                        .padding(.top, 5)
                }
            }
            .padding(8)
        }
        .frame(width: 110, height: 110)
        .onTapGesture {
            activeSlot = .amp
        }
    }
}
