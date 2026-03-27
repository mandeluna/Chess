//
//  GameHistoryView.swift
//  Shambolic
//

import SwiftUI
import UIKit

// MARK: - History Tab

struct GameHistoryView: View {
    @EnvironmentObject var gameState: ChessGame
    @Environment(\.dismiss) private var dismiss
    @State private var pendingLoad: GameRecord?

    var body: some View {
        Group {
            if gameState.allGames.isEmpty {
                Text("No games yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(gameState.allGames) { record in
                    GameHistoryRow(record: record)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if record.isCurrent {
                                dismiss()
                            } else if gameState.isGameOver || gameState.moveHistory.isEmpty {
                                gameState.loadGame(record)
                                dismiss()
                            } else {
                                pendingLoad = record
                            }
                        }
                        .listRowBackground(record.isCurrent
                            ? Color.accentColor.opacity(0.08)
                            : Color.clear)
                }
                .listStyle(.plain)
            }
        }
        .alert("Load this game?", isPresented: Binding(
            get: { pendingLoad != nil },
            set: { if !$0 { pendingLoad = nil } }
        )) {
            Button("Load", role: .destructive) {
                if let r = pendingLoad { gameState.loadGame(r) }
                pendingLoad = nil
                dismiss()
            }
            Button("Cancel", role: .cancel) { pendingLoad = nil }
        } message: {
            Text("The current game is still in progress.")
        }
    }
}

// MARK: - Row

private struct GameHistoryRow: View {
    let record: GameRecord
    @EnvironmentObject var gameState: ChessGame

    private var displayPGN: String {
        record.isCurrent ? gameState.pgn : record.pgn
    }

    private var displayCP: Int? {
        record.isCurrent ? gameState.engineScore : record.finalCP
    }

    var body: some View {
        HStack(spacing: 10) {
            BoardThumbnailView(fen: record.isCurrent ? gameState.currentFEN : record.finalFEN)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    outcomeLabel
                    if record.isCurrent {
                        Text("NOW PLAYING")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(record.startedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if let cp = displayCP {
                    let pawns = Double(cp) / 100.0
                    Text(pawns >= 0 ? String(format: "+%.2f", pawns) : String(format: "%.2f", pawns))
                        .font(.caption2.monospaced())
                        .foregroundStyle(cp > 50 ? .green : cp < -50 ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var outcomeLabel: some View {
        if let outcome = record.outcome {
            Text(outcome.displayString)
                .font(.caption.weight(.semibold))
                .foregroundStyle(outcomeColor(outcome))
        } else {
            Text("In progress")
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }
    }

    private func outcomeColor(_ outcome: GameRecord.Outcome) -> Color {
        switch outcome {
        case .white: return record.humanColor == .white ? .green : .red
        case .black: return record.humanColor == .black ? .green : .red
        case .draw:  return .secondary
        }
    }
}

// MARK: - Board Thumbnail

struct BoardThumbnailView: View {
    let fen: String

    var body: some View {
        Canvas { context, size in
            let sq = size.width / 8
            let light = Color(red: 0.93, green: 0.87, blue: 0.77)
            let dark  = Color(red: 0.57, green: 0.42, blue: 0.31)

            for rank in 0..<8 {
                for file in 0..<8 {
                    let rect = CGRect(x: CGFloat(file) * sq,
                                     y: CGFloat(rank) * sq,
                                     width: sq, height: sq)
                    context.fill(Path(rect), with: .color((rank + file) % 2 == 0 ? dark : light))
                }
            }
            for (square, imageName) in parsedPieces {
                let file = square % 8
                let displayRank = 7 - (square / 8)
                let rect = CGRect(x: CGFloat(file) * sq,
                                  y: CGFloat(displayRank) * sq,
                                  width: sq, height: sq)
                if let uiImage = UIImage(named: imageName) {
                    context.draw(Image(uiImage: uiImage), in: rect)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var parsedPieces: [(square: Int, imageName: String)] {
        let placement = fen.components(separatedBy: " ").first ?? ""
        var result: [(Int, String)] = []
        var rank = 7
        var file = 0
        for ch in placement {
            switch ch {
            case "/": rank -= 1; file = 0
            case "1"..."8": file += ch.wholeNumberValue ?? 1
            default:
                if let name = pieceImageName(ch) {
                    result.append((rank * 8 + file, name))
                }
                file += 1
            }
        }
        return result
    }

    private func pieceImageName(_ ch: Character) -> String? {
        switch ch {
        case "K": return "whiteKingImage";   case "Q": return "whiteQueenImage"
        case "R": return "whiteRookImage";   case "B": return "whiteBishopImage"
        case "N": return "whiteKnightImage"; case "P": return "whitePawnImage"
        case "k": return "blackKingImage";   case "q": return "blackQueenImage"
        case "r": return "blackRookImage";   case "b": return "blackBishopImage"
        case "n": return "blackKnightImage"; case "p": return "blackPawnImage"
        default: return nil
        }
    }
}

// MARK: - Preview

#Preview {
    GameHistoryView()
        .environmentObject(ChessGame())
}
