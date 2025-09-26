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
    @State private var showAnalysis = false
    @State private var showSettings = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Game controls
            HStack(spacing: 12) {
                MenuButton(
                    icon: "line.3.horizontal",
                    action: { showSidebar.toggle() }
                )
                
                MenuButton(
                    icon: "arrow.clockwise",
                    action: gameState.resetGame
                )
            }
            
            Spacer()
            
            // Center - Game status
            VStack(spacing: 2) {
                Text(gameStatusText)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let evaluation = gameState.analysis?.evaluation {
                    Text(evaluationText(evaluation))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(evaluationColor(evaluation))
                }
            }
            
            Spacer()
            
            // Right side - Analysis and settings
            HStack(spacing: 12) {
                MenuButton(
                    icon: "chart.bar",
                    action: { showAnalysis = true }
                )
                .disabled(gameState.analysis == nil)
                
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
        .sheet(isPresented: $showAnalysis) {
            AnalysisView(analysis: gameState.analysis)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private var gameStatusText: String {
        return gameState.statusMessage
    }
    
    private func evaluationText(_ evaluation: Double) -> String {
        if evaluation > 0 {
            return "+\(String(format: "%.1f", evaluation))"
        } else {
            return "\(String(format: "%.1f", evaluation))"
        }
    }
    
    private func evaluationColor(_ evaluation: Double) -> Color {
        if evaluation > 0.5 { return .green }
        else if evaluation < -0.5 { return .red }
        else { return .primary }
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
    CompactTopMenu(showSidebar: .constant(false))
        .environmentObject(ChessGame())
}
