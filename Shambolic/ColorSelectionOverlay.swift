//
//  ColorSelectionOverlay.swift
//  Shambolic
//
//  Created by Steve Wart on 2026-03-20.
//

import SwiftUI

struct ColorSelectionOverlay: View {
    @EnvironmentObject var gameState: ChessGame
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("New Game")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Choose your side")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 20) {
                    SideChoiceButton(
                        label: "White",
                        symbol: "♔",
                        circleFill: .white,
                        symbolColor: .black,
                        bordered: true
                    ) {
                        gameState.setHumanColor(.white)
                    }

                    SideChoiceButton(
                        label: "Random",
                        symbol: "🎲",
                        circleFill: Color(.systemGray4),
                        symbolColor: .primary,
                        bordered: false
                    ) {
                        gameState.setHumanColor(Bool.random() ? .white : .black)
                    }

                    SideChoiceButton(
                        label: "Black",
                        symbol: "♚",
                        circleFill: .black,
                        symbolColor: .white,
                        bordered: true
                    ) {
                        gameState.setHumanColor(.black)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(colorScheme == .dark
                          ? Color(.systemGray6)
                          : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 8)
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Side Choice Button

private struct SideChoiceButton: View {
    let label: String
    let symbol: String
    let circleFill: Color
    let symbolColor: Color
    let bordered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(circleFill)
                        .frame(width: 76, height: 76)
                    if bordered {
                        Circle()
                            .strokeBorder(Color(.separator), lineWidth: 1)
                            .frame(width: 76, height: 76)
                    }
                    Text(symbol)
                        .font(.system(size: 42))
                        .foregroundStyle(symbolColor)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ColorSelectionOverlay()
        .environmentObject(ChessGame())
}
