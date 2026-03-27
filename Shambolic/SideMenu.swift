//
//  SideMenu.swift
//  Shambolic
//
//  Created by Steve Wart on 2025-09-24.
//

import SwiftUI

struct SideMenu: View {
    @EnvironmentObject var gameState: ChessGame

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            TabView(selection: $selectedTab) {
                ScrollView {
                    analysisSection.padding(16)
                }
                .tabItem { Label("Analysis", systemImage: "chart.bar") }
                .tag(0)

                GameHistoryView()
                    .tabItem { Label("History", systemImage: "clock") }
                    .tag(1)
            }
        }
        .frame(width: 280)
        .background(.regularMaterial)
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

}

// MARK: - Preview

#Preview {
    SideMenu()
        .environmentObject(ChessGame())
        .environmentObject(ChessSettings())
}
