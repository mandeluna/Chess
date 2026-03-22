//
//  AnalysisView.swift
//  Shambolic
//

import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var gameState: ChessGame
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    evaluationSection
                    principalVariationSection
                }
                .padding()
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var evaluationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evaluation")
                .font(.headline)

            HStack(spacing: 12) {
                EvaluationBar(centipawns: gameState.engineScore ?? 0)

                Text(evaluationText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(evaluationColor)
                    .monospacedDigit()
            }

            HStack {
                Text(evaluationDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if gameState.thinkingDepth > 0 {
                    Text("depth \(gameState.thinkingDepth)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }

    private var principalVariationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Principal Variation")
                .font(.headline)

            let moves = pvMoves
            if moves.isEmpty {
                Text(gameState.moveHistory.isEmpty ? "Start a game to see analysis." : "Waiting for engine…")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                // Display as numbered move pairs (White Black)
                let pairs = movePairs(moves)
                ForEach(Array(pairs.enumerated()), id: \.offset) { idx, pair in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(idx + 1).")
                            .foregroundColor(.secondary)
                            .frame(width: 28, alignment: .trailing)
                        Text(pair.white)
                            .monospaced()
                        if let black = pair.black {
                            Text(black)
                                .monospaced()
                        }
                    }
                    .font(.body)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }

    // MARK: - Helpers

    private var pvMoves: [String] {
        gameState.thinkingLine
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private struct MovePair {
        let white: String
        let black: String?
    }

    private func movePairs(_ moves: [String]) -> [MovePair] {
        stride(from: 0, to: moves.count, by: 2).map { i in
            MovePair(white: moves[i], black: i + 1 < moves.count ? moves[i + 1] : nil)
        }
    }

    private var evaluationText: String {
        guard let cp = gameState.engineScore else { return "—" }
        let pawns = Double(cp) / 100.0
        return pawns >= 0 ? String(format: "+%.2f", pawns) : String(format: "%.2f", pawns)
    }

    private var evaluationColor: Color {
        guard let cp = gameState.engineScore else { return .gray }
        if cp > 50 { return .green }
        if cp < -50 { return .red }
        return .primary
    }

    private var evaluationDescription: String {
        guard let cp = gameState.engineScore else { return "" }
        switch cp {
        case ..<(-200): return "Black has a winning advantage"
        case -200 ..< -100: return "Black has a significant advantage"
        case -100 ..< -50:  return "Black has a slight advantage"
        case -50  ..< 50:   return "Position is roughly equal"
        case 50   ..< 100:  return "White has a slight advantage"
        case 100  ..< 200:  return "White has a significant advantage"
        default:            return "White has a winning advantage"
        }
    }
}

// MARK: - EvaluationBar

struct EvaluationBar: View {
    let centipawns: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                Rectangle()
                    .fill(barColor)
                    .frame(width: barWidth(in: geo))
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .cornerRadius(4)
        }
        .frame(height: 8)
    }

    private func barWidth(in geo: GeometryProxy) -> CGFloat {
        let clamped = min(max(Double(centipawns), -500), 500)
        let pct = (clamped + 500) / 1000
        return geo.size.width * CGFloat(pct)
    }

    private var barColor: Color { centipawns >= 0 ? .green : .red }
}

// MARK: - Preview

#Preview {
    AnalysisView()
        .environmentObject({
            let g = ChessGame()
            g.engineScore = 142
            g.thinkingDepth = 18
            g.thinkingLine = "e2e4 e7e5 g1f3 b8c6 f1b5"
            return g
        }())
}
