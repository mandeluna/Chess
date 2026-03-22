//
//  SideMenu.swift
//  Shambolic
//
//  Created by Steve Wart on 2025-09-24.
//

import SwiftUI

struct SideMenu: View {
    @EnvironmentObject var gameState: ChessGame
    @Environment(\.dismiss) private var dismiss
    @State private var showPosition = false
    @State private var showResignConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 20) {
                    analysisSection
                    actionsSection
                }
                .padding(16)
            }
        }
        .frame(width: 280)
        .background(.regularMaterial)
        .sheet(isPresented: $showPosition) {
            PositionSheet()
                .environmentObject(gameState)
        }
        .alert("Resign?", isPresented: $showResignConfirm) {
            Button("Resign", role: .destructive) {
                dismiss()
                gameState.resetGame()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("End the current game and start a new one.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Chess")
                .font(.headline)
            Spacer()
            Text(gameState.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Analysis

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Analysis", systemImage: "chart.bar")
                .font(.subheadline.weight(.semibold))

            if let cp = gameState.engineScore {
                let pawns = Double(cp) / 100.0
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(pawns >= 0 ? String(format: "+%.2f", pawns) : String(format: "%.2f", pawns))
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                        .foregroundStyle(cp > 50 ? .green : cp < -50 ? .red : .primary)
                    Text("cp")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if gameState.thinkingDepth > 0 {
                        Spacer()
                        Text("depth \(gameState.thinkingDepth)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !gameState.thinkingLine.isEmpty {
                    Text(gameState.thinkingLine)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("No analysis yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Actions

    private var actionsSection: some View {
        VStack(spacing: 10) {
            if gameState.isGameOver || gameState.moveHistory.isEmpty {
                // No active game — offer to start one
                Button {
                    dismiss()
                    gameState.resetGame()
                } label: {
                    Label("New Game", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                // Game in progress
                Button {
                    showResignConfirm = true
                } label: {
                    Label("Resign", systemImage: "flag")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.large)
            }

            Button {
                showPosition = true
            } label: {
                Label("Share Position", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }
}

// MARK: - Preview

#Preview {
    SideMenu()
        .environmentObject(ChessGame())
        .environmentObject(ChessSettings())
}
