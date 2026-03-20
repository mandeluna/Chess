//
//  CompactTopMenu.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//

import SwiftUI

struct CompactTopMenu: View {
    @EnvironmentObject var gameState: ChessGame
    @Binding var showSidebar: Bool
    @Binding var showResign: Bool
    @State private var showSettings = false
    @State private var showPosition = false

    var body: some View {
        HStack(spacing: 16) {
            // Left — sidebar + resign
            HStack(spacing: 12) {
                MenuButton(
                    icon: "line.3.horizontal",
                    action: { showSidebar.toggle() }
                )

                MenuButton(
                    icon: "flag",
                    action: { showResign = true }
                )
                .disabled(gameState.moveHistory.isEmpty)
            }

            Spacer()

            // Center — current player indicator
            Text(gameState.currentPlayer == .white ? "♔ White" : "♚ Black")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            // Right — position/share + settings
            HStack(spacing: 12) {
                MenuButton(
                    icon: "square.and.arrow.up",
                    action: { showPosition = true }
                )
                MenuButton(
                    icon: "gearshape",
                    action: { showSettings = true }
                )
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showPosition) {
            PositionSheet()
                .environmentObject(gameState)
        }
    }
}

struct MenuButton: View {
    let icon: String
    let action: () -> Void
    var badge: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                
                if badge {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
}

#Preview {
    CompactTopMenu(showSidebar: .constant(false), showResign: .constant(false))
        .environmentObject(ChessGame())
}
