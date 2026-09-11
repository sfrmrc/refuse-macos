// WelcomeView.swift
// Migrazione di welcome.ts — schermata iniziale

import SwiftUI

struct WelcomeView: View {
    @Environment(FuseAPI.self) private var api
    @State private var isConnecting = false
    @State private var connectionError: String?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.07, blue: 0.12),
                         Color(red: 0.12, green: 0.05, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                // Logo / Title
                VStack(spacing: 12) {
                    Image(systemName: "music.amplifier")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .red],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 20)

                    Text("ReFUSE")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Color(white: 0.75)],
                                           startPoint: .top, endPoint: .bottom)
                        )

                    Text("Unofficial Fender FUSE Replacement")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                // Description
                VStack(spacing: 8) {
                    featureRow(icon: "cable.connector", text: "Connect via USB to your Fender Mustang amp")
                    featureRow(icon: "slider.horizontal.3", text: "Edit presets, effects and hidden amp models")
                    featureRow(icon: "arrow.left.arrow.right", text: "Drag & drop effects in the signal chain")
                }
                .padding(24)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Connect button
                VStack(spacing: 12) {
                    Button {
                        Task { await connect() }
                    } label: {
                        HStack(spacing: 10) {
                            if isConnecting {
                                ProgressView().controlSize(.small).tint(.white)
                            } else {
                                Image(systemName: "cable.connector.horizontal")
                            }
                            Text(isConnecting ? "Connecting…" : "Connect Amp")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(minWidth: 200)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 32)
                        .background(
                            LinearGradient(colors: [.orange, .red],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .orange.opacity(0.4), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isConnecting)
                    .scaleEffect(isConnecting ? 0.97 : 1.0)
                    .animation(.spring(duration: 0.2), value: isConnecting)

                    if let error = connectionError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }

                    Text("Requires Chrome, Edge, or Opera for WebHID • macOS: uses IOKit")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(60)
        }
        .preferredColorScheme(.dark)
    }

    private func connect() async {
        isConnecting = true
        connectionError = nil
        let success = await api.connect()
        if !success {
            connectionError = "Could not connect. Make sure your Mustang amp is plugged in via USB."
        }
        isConnecting = false
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
        }
    }
}
