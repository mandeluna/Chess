//
//  AnalysisView.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//

import Foundation
import SwiftUI

struct AnalysisView: View {
    let analysis: LichessAnalysis?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Position Evaluation
                    evaluationSection
                    
                    // Best Move
                    bestMoveSection
                    
                    // Principal Variation
                    principalVariationSection
                    
                    // Engine Suggestions
                    suggestionsSection
                    
                    // Position Insights
                    insightsSection
                }
                .padding()
            }
            .navigationTitle("Position Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var evaluationSection: some View {
        VStack(alignment: .leading) {
            Text("Position Evaluation")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                EvaluationBar(evaluation: analysis?.evaluation ?? 0.0)
                
                Text(evaluationText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(evaluationColor)
            }
            
            Text(evaluationDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private var bestMoveSection: some View {
        VStack(alignment: .leading) {
            Text("Best Move")
                .font(.headline)
            
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                
                Text(analysis?.bestMove ?? "N/A")
                    .font(.title2)
                    .fontWeight(.medium)
                    .monospaced()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private var principalVariationSection: some View {
        VStack(alignment: .leading) {
            Text("Principal Variation")
                .font(.headline)
            
            LazyVStack(alignment: .leading) {
                ForEach(Array((analysis?.pv ?? []).enumerated()), id: \.offset) { index, move in
                    HStack {
                        Text("\(index + 1).")
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                        
                        Text(move)
                            .font(.body)
                            .monospaced()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading) {
            Text("Engine Suggestions")
                .font(.headline)
            
            Spacer()
            
            if let analysis = analysis {
                VStack(alignment: .leading, spacing: 8) {
                    if analysis.evaluation > 1.0 {
                        SuggestionRow(icon: "hand.thumbsup.fill",
                                    color: .green,
                                    text: "White has a significant advantage")
                    } else if analysis.evaluation < -1.0 {
                        SuggestionRow(icon: "hand.thumbsdown.fill",
                                    color: .red,
                                    text: "Black has a significant advantage")
                    } else {
                        SuggestionRow(icon: "scale.fill",
                                    color: .blue,
                                    text: "Position is roughly equal")
                    }
                    
                    if analysis.evaluation > 0.5 {
                        SuggestionRow(icon: "lightbulb.fill",
                                    color: .orange,
                                    text: "Consider developing your pieces")
                    }
                }
            } else {
                Text("No analysis available")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading) {
            Text("Position Insights")
                .font(.headline)
            
            InsightRow(metric: "Centipawn Loss", value: "12.4", trend: .down)
            InsightRow(metric: "Accuracy", value: "94%", trend: .up)
            InsightRow(metric: "Threat Level", value: "Low", trend: .neutral)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Computed Properties
    
    private var evaluationText: String {
        guard let evaluation = analysis?.evaluation else { return "N/A" }
        
        if evaluation > 0 {
            return "+\(String(format: "%.1f", evaluation))"
        } else {
            return "\(String(format: "%.1f", evaluation))"
        }
    }
    
    private var evaluationColor: Color {
        guard let evaluation = analysis?.evaluation else { return .gray }
        
        if evaluation > 0.5 { return .green }
        else if evaluation < -0.5 { return .red }
        else { return .blue }
    }
    
    private var evaluationDescription: String {
        guard let evaluation = analysis?.evaluation else { return "No evaluation available" }
        
        switch evaluation {
        case ...(-2.0): return "Black has a winning advantage"
        case -2.0...(-1.0): return "Black has a significant advantage"
        case -1.0...(-0.5): return "Black has a slight advantage"
        case -0.5...0.5: return "Position is equal"
        case 0.5...1.0: return "White has a slight advantage"
        case 1.0...2.0: return "White has a significant advantage"
        default: return "White has a winning advantage"
        }
    }
}

// MARK: - Supporting Views

struct EvaluationBar: View {
    let evaluation: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                // Evaluation indicator
                Rectangle()
                    .fill(evaluationColor)
                    .frame(width: barWidth(in: geometry), height: 8)
                
                // Center line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 12)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .cornerRadius(4)
        }
        .frame(height: 8)
    }
    
    private func barWidth(in geometry: GeometryProxy) -> CGFloat {
        let maxEvaluation: Double = 5.0
        let normalizedEvaluation = min(max(evaluation, -maxEvaluation), maxEvaluation)
        let percentage = (normalizedEvaluation + maxEvaluation) / (2 * maxEvaluation)
        return geometry.size.width * CGFloat(percentage)
    }
    
    private var evaluationColor: Color {
        evaluation > 0 ? .green : .red
    }
}

struct SuggestionRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct InsightRow: View {
    let metric: String
    let value: String
    let trend: Trend
    
    enum Trend { case up, down, neutral }
    
    var body: some View {
        HStack {
            Text(metric)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
            
            Image(systemName: trendIcon)
                .foregroundColor(trendColor)
                .font(.caption)
        }
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - Data Models

struct LichessAnalysis {
    let evaluation: Double
    let bestMove: String
    let pv: [String] // Principal variation
    let depth: Int
}

// MARK: - Preview
#Preview("AnalysisView") {
    AnalysisView(analysis: LichessAnalysis(
        evaluation: 1.5,
        bestMove: "e4e5",
        pv: ["e4", "e5", "Nf3", "Nc6", "Bb5"],
        depth: 25
    ))
}
