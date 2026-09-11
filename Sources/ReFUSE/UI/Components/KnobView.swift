// KnobView.swift
// Manopola personalizzata disegnata con Canvas — equivalente di knob.ts

import SwiftUI

struct KnobView: View {
    let name: String
    let value: Int   // 0..255
    var onChange: ((Int) -> Void)?

    @State private var dragStart: CGFloat? = nil
    @State private var valueAtDragStart: Int = 0
    private let size: CGFloat = 60

    private var normalizedValue: Double { Double(value) / 255.0 }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Track arc
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .frame(width: size, height: size)

                // Value arc
                Circle()
                    .trim(from: 0.15, to: 0.15 + normalizedValue * 0.7)
                    .stroke(
                        LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: size, height: size)
                    .animation(.spring(duration: 0.15), value: value)

                // Knob cap
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.28), Color(white: 0.14)],
                            center: .topLeading,
                            startRadius: 2, endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 0.65, height: size * 0.65)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                // Indicator dot
                Canvas { ctx, sz in
                    let angle = (0.15 + normalizedValue * 0.7) * 2 * .pi
                    let r = sz.width * 0.265
                    let cx = sz.width / 2 + r * cos(angle - .pi / 2)
                    let cy = sz.height / 2 + r * sin(angle - .pi / 2)
                    var path = Path()
                    path.addEllipse(in: CGRect(x: cx - 2.5, y: cy - 2.5, width: 5, height: 5))
                    ctx.fill(path, with: .color(.orange))
                }
                .frame(width: size * 0.65, height: size * 0.65)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if dragStart == nil {
                            dragStart = drag.startLocation.y
                            valueAtDragStart = value
                        }
                        let delta = dragStart! - drag.location.y
                        let newValue = max(0, min(255, valueAtDragStart + Int(delta * 1.5)))
                        onChange?(newValue)
                    }
                    .onEnded { _ in dragStart = nil }
            )
            .cursor(.resizeUpDown)

            Text(name)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            Text("\(Int(normalizedValue * 100))%")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.orange.opacity(0.8))
        }
    }
}

// MARK: - Cursor Helper

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}
