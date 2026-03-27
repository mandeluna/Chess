//
//  ColorSelectionOverlay.swift
//  Shambolic
//
//  Created by Steve Wart on 2026-03-20.
//

import SwiftUI
import UIKit

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
                        circleFill: .white,
                        bordered: true,
                        action: { gameState.setHumanColor(.white) }
                    ) {
                        PieceImage(named: "whiteKingImage")
                    }

                    SideChoiceButton(
                        label: "Random",
                        circleFill: Color(.systemGray4),
                        bordered: false,
                        action: { gameState.setHumanColor(Bool.random() ? .white : .black) }
                    ) {
                        Image(systemName: "die.face.5")
                            .font(.system(size: 36, weight: .regular))
                            .foregroundStyle(.primary)
                    }

                    SideChoiceButton(
                        label: "Black",
                        circleFill: .black,
                        bordered: true,
                        action: { gameState.setHumanColor(.black) }
                    ) {
                        PieceImage(named: "blackKingImage")
                            .shadow(color: .white.opacity(0.55), radius: 3, x: 0, y: 0)
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

// MARK: - Piece Image

/// Loads a bundle image by filename (e.g. "whiteKingImage.png") and renders it
/// resizable, fitting within a fixed square.
private struct PieceImage: View {
    let named: String

    var body: some View {
        if let uiImage = UIImage(named: named) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 46, height: 46)
        }
    }
}

// MARK: - Side Choice Button

private struct SideChoiceButton<Icon: View>: View {
    let label: String
    let circleFill: Color
    let bordered: Bool
    let action: () -> Void
    let icon: Icon

    init(
        label: String,
        circleFill: Color,
        bordered: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.label = label
        self.circleFill = circleFill
        self.bordered = bordered
        self.action = action
        self.icon = icon()
    }

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
                    icon
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
