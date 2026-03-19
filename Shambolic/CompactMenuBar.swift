//
//  CompactMenuBar.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//

import SwiftUI

// Example 4. Compact Menu Design

struct CompactMenuBar: View {
    @EnvironmentObject var gameState: ChessGame
    @Binding var showSidebar: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Menu button with explicit tap area
            Button(action: {
                withAnimation(.spring()) {
                    showSidebar.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            HStack {
                MenuButton(icon: "arrow.clockwise", action: gameState.resetGame)
                Spacer()
                Text("Chess")
                    .font(.headline)
                Spacer()
                MenuButton(icon: "chart.bar", action: {})
            }
            .padding(.horizontal)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
        }
        // Ensure menu is always tappable
        .allowsHitTesting(true)
        .zIndex(10) // High z-index to stay above other views
    }
}

#Preview {
    CompactMenuBar(showSidebar: .constant(true))
        .environmentObject(ChessGame())
}
