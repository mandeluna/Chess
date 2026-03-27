//
//  ChessView.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-22.
//

import SwiftUI

struct ChessView: View {
    @EnvironmentObject var gameState: ChessGame
    @State private var showMenuSheet = false

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            let isCompact = geometry.size.width < 400

            if isPortrait || isCompact {
                portraitLayout(geometry: geometry)
            } else {
                landscapeLayout
            }
        }
        .overlay {
            if gameState.showColorSelection {
                ColorSelectionOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: gameState.showColorSelection)
        .sheet(isPresented: $showMenuSheet) {
            SideMenu()
        }
    }

    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            CompactTopMenu(showSidebar: $showMenuSheet)

            ChessBoardViewWrapper()
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: geometry.size.width)

            CompactBottomPanel()
                .frame(maxHeight: .infinity)
        }
    }

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            SideMenu()
            ChessBoardViewWrapper()
        }
    }
}

// MARK: - Compact Bottom Panel (portrait)

struct CompactBottomPanel: View {
    @EnvironmentObject var gameState: ChessGame

    var body: some View {
        VStack(spacing: 0) {
            CapturedBar()
                .environmentObject(gameState)

            ScoreBar()
                .environmentObject(gameState)

            Divider()

            if gameState.isThinking {
                ThinkingPanel()
                    .environmentObject(gameState)
                Divider()
            }

            PGNHistoryView()
                .environmentObject(gameState)
        }
    }
}

// MARK: - Captured Pieces Bar

struct CapturedBar: View {
    @EnvironmentObject var gameState: ChessGame

    var body: some View {
        let blackCaptures = gameState.capturedPieces.compressPieces(isWhite: true)   // white pieces black took
        let whiteCaptures = gameState.capturedPieces.compressPieces(isWhite: false)  // black pieces white took

        VStack(spacing: 0) {
            capturedRow(pieces: blackCaptures, label: "♚")
            capturedRow(pieces: whiteCaptures, label: "♔")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private func capturedRow(pieces: [(type: PieceType, count: Int)], label: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            if pieces.isEmpty {
                Text("—")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                PieceView(pieces: pieces, isWhite: false)
            }
            Spacer()
        }
        .frame(height: 20)
    }
}

// MARK: - Thinking Panel

struct ThinkingPanel: View {
    @EnvironmentObject var gameState: ChessGame

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.65)
                Text("Depth \(gameState.thinkingDepth)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
            }
            if !gameState.thinkingLine.isEmpty {
                Text(gameState.thinkingLine)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
    }
}

// MARK: - Score Bar

struct ScoreBar: View {
    @EnvironmentObject var gameState: ChessGame

    private var evalText: String {
        guard let cp = gameState.engineScore else { return "?" }
        let pawns = Double(cp) / 100.0
        if pawns > 0 { return String(format: "+%.2f", pawns) }
        if pawns < 0 { return String(format: "%.2f", pawns) }
        return "0.00"
    }

    private var evalColor: Color {
        guard let cp = gameState.engineScore else { return .secondary }
        if cp > 20 { return .green }
        if cp < -20 { return .red }
        return .primary
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(gameState.statusMessage)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 3) {
                Text(evalText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(evalColor)
                Text("cp")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - PGN History View (portrait, compact)

struct PGNHistoryView: View {
    @EnvironmentObject var gameState: ChessGame
    @State private var showCopied = false

    /// Pair up SAN moves: [(moveNumber, white, black?)]
    private var movePairs: [(Int, String, String?)] {
        let sans = gameState.moveHistorySAN
        var pairs: [(Int, String, String?)] = []
        var i = 0
        while i < sans.count {
            let white = sans[i]
            let black = i + 1 < sans.count ? sans[i + 1] : nil
            pairs.append((i / 2 + 1, white, black))
            i += 2
        }
        return pairs
    }

    private func copyPGN() {
        UIPasteboard.general.string = gameState.pgn
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                showCopied = false
            }
        }
    }

    var body: some View {
        Group {
            if gameState.moveHistorySAN.isEmpty {
                Text("No moves yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(movePairs, id: \.0) { number, white, black in
                                HStack(spacing: 4) {
                                    Text("\(number).")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 28, alignment: .trailing)
                                    Text(white)
                                        .font(.system(.caption, design: .monospaced))
                                        .frame(width: 52, alignment: .leading)
                                    if let black = black {
                                        Text(black)
                                            .font(.system(.caption, design: .monospaced))
                                            .frame(width: 52, alignment: .leading)
                                    }
                                    Spacer()
                                }
                                .id(number)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .onChange(of: gameState.moveHistorySAN.count) { _ in
                        if let last = movePairs.last {
                            withAnimation { proxy.scrollTo(last.0, anchor: .bottom) }
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .onLongPressGesture(perform: copyPGN)
        .overlay(alignment: .center) {
            if showCopied {
                Text("Copied!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ChessView()
        .environmentObject(ChessGame())
        .environmentObject(ChessSettings())
}
