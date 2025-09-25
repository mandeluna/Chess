//
//  SideMenu.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//

import SwiftUI

struct SideMenu: View {
    @EnvironmentObject var gameState: ChessGame
    @State private var selectedTab: MenuTab = .game
    @State private var showAnalysis = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with compact game info
            VStack(spacing: 8) {
                Text("Chess")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(gameState.currentPlayer == .white ? "♔ White" : "♚ Black")
                    .font(.caption)
                    .foregroundColor(gameState.currentPlayer == .white ? .primary : .gray)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground).opacity(0.9))
            
            // Tab selection
            HStack(spacing: 0) {
                ForEach(MenuTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
            }
            
            // Tab content
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .game:
                        GameControlsView()
                    case .analysis:
                        AnalysisPreviewView()
                    case .history:
                        MoveHistoryView()
                    case .captured:
                        CapturedPiecesView()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            
            Spacer()
            
            // Bottom controls
            VStack(spacing: 8) {
                Button(action: gameState.resetGame) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("New Game")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if gameState.analysis != nil {
                    Button(action: { showAnalysis = true }) {
                        HStack {
                            Image(systemName: "chart.bar")
                            Text("Analyze")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground).opacity(0.9))
        }
        .frame(width: 280)
        .background(.regularMaterial)
        .sheet(isPresented: $showAnalysis) {
            AnalysisView(analysis: gameState.analysis)
        }
    }
}

// MARK: - Supporting Types and Views

enum MenuTab: CaseIterable {
    case game, analysis, history, captured
    
    var iconName: String {
        switch self {
        case .game: return "gamecontroller"
        case .analysis: return "chart.bar"
        case .history: return "clock"
        case .captured: return "captions.bubble"
        }
    }
    
    var title: String {
        switch self {
        case .game: return "Game"
        case .analysis: return "Analysis"
        case .history: return "History"
        case .captured: return "Captured"
        }
    }
}

// MARK: - Tab Content Views

struct GameControlsView: View {
    @EnvironmentObject var gameState: ChessGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Controls")
                .font(.headline)
            
            VStack(spacing: 8) {
                Toggle("Show Legal Moves", isOn: Binding(
                    get: { gameState.showLegalMoves },
                    set: { gameState.showLegalMoves = $0 }
                ))
                
                Toggle("Highlight Checks", isOn: Binding(
                    get: { gameState.highlightChecks },
                    set: { gameState.highlightChecks = $0 }
                ))
                
                Stepper("Move Time: \(gameState.moveTime)s", value: Binding(
                    get: { Int(gameState.moveTime) },
                    set: { gameState.moveTime = Double($0) }
                ), in: 1...60)
            }
            .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AnalysisPreviewView: View {
    @EnvironmentObject var gameState: ChessGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position Analysis")
                .font(.headline)
            
            if let analysis = gameState.analysis {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Evaluation:")
                        Text(analysis.evaluation > 0 ? "+\(String(format: "%.1f", analysis.evaluation))" : "\(String(format: "%.1f", analysis.evaluation))")
                            .foregroundColor(analysis.evaluation > 0 ? .green : .red)
                            .fontWeight(.medium)
                    }
                    
                    Text("Best: \(analysis.bestMove)")
                        .font(.system(.caption, design: .monospaced))
                    
                    Text("Depth: \(analysis.depth)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No analysis available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoveHistoryView: View {
    @EnvironmentObject var gameState: ChessGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Move History")
                .font(.headline)
            
            if gameState.moveHistory.isEmpty {
                Text("No moves yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(gameState.moveHistory.enumerated()), id: \.offset) { index, move in
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(.caption, design: .monospaced))
                                .frame(width: 24, alignment: .trailing)
                            
                            Text(move.uciString())
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CapturedPiecesView: View {
    @EnvironmentObject var gameState: ChessGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Captured Pieces")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("White captured:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if gameState.capturedPieces.white.isEmpty {
                    Text("None")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    CapturedPiecesRow(pieces: gameState.capturedPieces.white)
                }
                
                Text("Black captured:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if gameState.capturedPieces.black.isEmpty {
                    Text("None")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    CapturedPiecesRow(pieces: gameState.capturedPieces.black)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CapturedPiecesRow: View {
    let pieces: [ChessPiece]
    
    var body: some View {
        LazyHGrid(rows: [GridItem(.fixed(16))], spacing: 4) {
            ForEach(pieces, id: \.piece) { piece in
                Text(piece.type.symbol)
                    .font(.system(size: 12))
            }
        }
    }
}

#Preview {
    SideMenu()
        .environmentObject(ChessGame())
}
