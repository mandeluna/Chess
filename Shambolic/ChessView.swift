//
//  ChessView.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-22.
//

import SwiftUI

struct ChessView: View {
    @StateObject private var gameState = ChessGame()
    @State private var showingAnalysis = false
    @State private var showMenuSheet = false
    
    var body: some View {
        // Main Chessboard
        chessboard
    }
    
    private var chessboard: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            let isCompact = geometry.size.width < 400
            
            if isPortrait || isCompact {
                // Portrait or compact layout
                VStack(spacing: 0) {
                    CompactTopMenu(showSidebar: $showMenuSheet)
                        .environmentObject(gameState)
                    
                    ChessBoardViewWrapper()
                        .environmentObject(gameState)
                    
                    Text(gameState.statusMessage)
                }
            } else {
                // Landscape layout
                HStack(spacing: 0) {
                    SideMenu()
                        .frame(width: 280)
                        .environmentObject(gameState)
                    
                    ChessBoardViewWrapper()
                        .environmentObject(gameState)
                }
            }
        }
    }

    private func playerIndicatorView() -> some View {
        Text(gameState.statusMessage)
    }
    
    private func capturedPiecesView(for color: PieceColor) -> some View {
        let isWhite = color == .white
        return VStack(alignment: .leading) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                ForEach(gameState.capturedPieces(for: color), id: \.self) { piece in
                    PieceView(pieces:gameState.capturedPieces.compressPieces(isWhite: isWhite), isWhite:isWhite)
                        .frame(width: 25, height: 25)
                }
            }
        }
    }
    
    private func moveHistoryView() -> some View {
        VStack {
            Text("Move History")
                .font(.headline)
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(Array(gameState.moveHistory.enumerated()), id: \.offset) { index, move in
                        HStack {
                            Text("\(index + 1).")
                            Text(move.uciString())
//                            if let evaluation = move.analysis?.evaluation {
//                                Text(String(format: "%.1f", evaluation))
//                                    .foregroundColor(evaluation > 0 ? .green : .red)
//                            }
                            let evaluation = move.value
                            Text(String(format: "%.1f", evaluation))
                                .foregroundColor(evaluation > 0 ? .green : .red)
                        }
                    }
                }
            }
            .frame(height: 150)
        }
        .padding()
    }
    
    private func gameControlsView() -> some View {
        VStack {
            Button("Analyze Position") {
                showingAnalysis = true
            }
            
            Button("Undo Move") {
                gameState.undoLastMove()
            }
            .disabled(gameState.moveHistory.isEmpty)
            
            Button("New Game") {
                gameState.resetGame()
            }
        }
    }
}

#Preview {
    ChessView()
}
