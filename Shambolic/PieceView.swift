//
//  PieceView.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//

import Foundation
import SwiftUI

struct PieceView: View {
    let pieces: [(type: PieceType, count: Int)]
    let isWhite: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(pieces, id: \.type) { item in
                HStack(spacing: 2) {
                    // always use filled symbols
                    Text(item.type.symbol)
                        .font(.custom("Apple Symbols", size: 16))
                    
                    if item.count > 1 {
                        Text("×\(item.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("PieceView") {

    let capturedPieces = CapturedPieces(
        white: [.pawn, .pawn, .pawn, .knight, .rook, .bishop, .rook]
            .map { ChessPiece(type:$0, square:-1, isWhite:false) },
        black: [.pawn, .pawn, .bishop, .rook, .queen, .bishop]
            .map { ChessPiece(type:$0, square:-1, isWhite:false) }
    )
    
    let whiteDisplay = capturedPieces.displayPieces(isWhite: true)
    let blackDisplay = capturedPieces.displayPieces(isWhite: true)
    
    let whiteCompressed = capturedPieces.compressPieces(isWhite: true)
    let blackCompressed = capturedPieces.compressPieces(isWhite: false)

    VStack(spacing: 20) {
        Text("Text output")
        Text("Captured white \(whiteDisplay)")
            .font(.custom("Apple Symbols", size: 16))
        Text("Captured black \(blackDisplay)")
            .font(.custom("Apple Symbols", size: 16))

        Text("Image display")
        HStack {
            Text("Captured white")
            PieceView(pieces:whiteCompressed, isWhite:false)
        }
        HStack {
            Text("Captured black")
            PieceView(pieces:blackCompressed, isWhite:false)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

let pieces = ["♟", "♞", "♝", "♜", "♛", "♚"]
#Preview("All Pieces") {
    ForEach(pieces, id: \.self) { piece in
        HStack {
            GlyphViewRepresentable(glyph: piece, fontName: "Apple Symbols", fontSize: 10, fillColor: .white, strokeColor: .darkGray, strokeWidth: 1)
                .frame(width: 44, height: 44)
            GlyphViewRepresentable(glyph: piece, fontName: "Apple Symbols", fontSize: 10, fillColor: .darkGray, strokeColor: .clear, strokeWidth: 1)
                .frame(width: 44, height: 44)
                .padding(8)
        }
    }
    .background(Color.gray.opacity(0.2))
}

// ♟ ♞ ♝ ♜ ♛ ♚
// ♙ ♘ ♗ ♖ ♕ ♔
#Preview("Fonts") {
    let fonts = ["Apple Symbols", "Menlo", "Arial Unicode MS", "STIX Two Math"]
    HStack {
        ForEach(fonts, id: \.self) { font in
            VStack {
                Text(font)
                    .font(.system(size:12))
                    ForEach(pieces, id: \.self) { piece in
                        GlyphViewRepresentable(glyph: piece, fontName: font, fontSize: 10, fillColor: .white, strokeColor: .darkGray, strokeWidth: 1)
                            .frame(width: 28, height: 28)
                    }
            }
        }
    }
    .background(Color.gray.opacity(0.2))
}

let emoji = ["→", "$", "℥", "©", "∆", "✈︎"]
#Preview("Other Symbols") {
    ForEach(emoji, id: \.self) { piece in
        HStack {
            GlyphViewRepresentable(glyph: piece, fontName: "Apple Symbols", fontSize: 10, fillColor: .darkGray, strokeColor: .darkGray, strokeWidth: 1)
                .frame(width: 66, height: 66)
        }
    }
    .background(Color.gray.opacity(0.2))
}
