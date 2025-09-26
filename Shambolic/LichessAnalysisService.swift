//
//  LichessAnalysisService.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//

import Foundation

@MainActor class LichessAnalysisService {
    // Mark as nonisolated(unsafe) if the client is truly thread-safe
    private let apiClient = APIClient()
    
    func analyzePosition(board: [[ChessPiece?]], maxDepth: Int = 20) async -> LichessAnalysis? {
        let fen = convertToFEN(board: board)
        
        do {
            // Lichess Cloud Eval API
            let response: LichessCloudEvalResponse = try await apiClient.get(
                "/api/cloud-eval",
                queryParams: [
                    "fen": fen,
                    "multiPv": "3",
                    "variant": "standard"
                ]
            )
            
            return LichessAnalysis(
                evaluation: response.evaluation,
                bestMove: response.pvs.first?.moves ?? "",
                pv: response.pvs.first?.moves.components(separatedBy: " ") ?? [],
                depth: response.depth
            )
            
        } catch {
            print("Lichess analysis failed: \(error)")
            return await performLocalAnalysis(board: board) // Fallback
        }
    }
    
    private func convertToFEN(board: [[ChessPiece?]]) -> String {
        // Simple FEN conversion for the position (without move counters)
        var fen = ""
        
        for row in board {
            var emptyCount = 0
            for piece in row {
                if let piece = piece {
                    if emptyCount > 0 {
                        fen += "\(emptyCount)"
                        emptyCount = 0
                    }
                    fen += piece.fenSymbol
                } else {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 {
                fen += "\(emptyCount)"
            }
            fen += "/"
        }
        
        fen = String(fen.dropLast()) // Remove trailing slash
        fen += " w - - 0 1" // Default move counters
        
        return fen
    }
    
    private func performLocalAnalysis(board: [[ChessPiece?]]) async -> LichessAnalysis {
        // Fallback simple analysis if Lichess API fails
        await Task.detached {
            // Simple material count evaluation
            let evaluation = await self.calculateMaterialAdvantage(board: board)
            
            return LichessAnalysis(
                evaluation: evaluation,
                bestMove: "",
                pv: [],
                depth: 0
            )
        }.value
    }
    
    private func calculateMaterialAdvantage(board: [[ChessPiece?]]) -> Double {
        var whiteMaterial = 0
        var blackMaterial = 0
        
        for row in board {
            for piece in row {
                guard let piece = piece else { continue }
                
                let value = piece.type.value
                
                if piece.isWhite {
                    whiteMaterial += value
                } else {
                    blackMaterial += value
                }
            }
        }
        
        return Double(whiteMaterial - blackMaterial) / 100.0 // Convert to pawns
    }
}

// MARK: - Lichess API Response Models

struct LichessCloudEvalResponse: Codable {
    let fen: String
    let knodes: Int
    let depth: Int
    let pvs: [PrincipalVariation]
    let evaluation: Double
    
    struct PrincipalVariation: Codable {
        let moves: String
        let cp: Int?
    }
    
    // Compute evaluation in pawns
    var evaluationInPawns: Double {
        if let cp = pvs.first?.cp {
            return Double(cp) / 100.0
        }
        return evaluation
    }
}

// MARK: - Extension for FEN Symbols

extension ChessPiece {
    var fenSymbol: String {
        let symbol: String
        switch type {
        case .pawn: symbol = "P"
        case .knight: symbol = "N"
        case .bishop: symbol = "B"
        case .rook: symbol = "R"
        case .queen: symbol = "Q"
        case .king: symbol = "K"
        default: symbol = "@"
        }
        
        return isWhite ? symbol : symbol.lowercased()
    }
}
