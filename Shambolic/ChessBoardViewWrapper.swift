//
//  ChessBoardViewWrapper.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-23.
//

import Foundation
import SwiftUI

struct ChessBoardViewWrapper: UIViewRepresentable {
    typealias UIViewType = ChessBoardView

    @EnvironmentObject var game: ChessGame

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let coordinator = context.coordinator

        // Keep board orientation in sync with the human player's color.
        let wantWhiteOnBottom = game.humanColor == .white
        if uiView.isWhiteOnBottom() != wantWhiteOnBottom {
            uiView.switchSides()
        }

        let moveCount = game.moveCount

        // Detect game reset (moveCount went backwards)
        if moveCount < coordinator.lastAnimatedMoveCount {
            coordinator.lastAnimatedMoveCount = 0
            coordinator.isUserMove = false
            uiView.clearLastMoveHighlight()
        }

        let isNewMove = moveCount > coordinator.lastAnimatedMoveCount
        guard isNewMove else {
            // No new move — just sync (covers initial layout, resize, etc.)
            uiView.updateBoard(game.pieces)
            return
        }

        coordinator.lastAnimatedMoveCount = moveCount

        // Update last-move highlight
        if let lastMove = game.lastMove {
            uiView.setLastMoveHighlight(
                from: Int(lastMove.sourceSquare),
                to: Int(lastMove.destinationSquare)
            )
        }

        if coordinator.isUserMove {
            // The drag already moved the piece visually; just sync state.
            coordinator.isUserMove = false
            uiView.updateBoard(game.pieces)
        } else {
            // Engine move: animate the sliding piece, then sync state.
            if let lastMove = game.lastMove {
                let pieces = game.pieces
                uiView.animateMove(
                    from: Int(lastMove.sourceSquare),
                    to: Int(lastMove.destinationSquare)
                ) {
                    uiView.updateBoard(pieces)
                }
            } else {
                uiView.updateBoard(game.pieces)
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, @MainActor ChessBoardViewDelegate {
        var parent: ChessBoardViewWrapper
        var lastAnimatedMoveCount: Int = 0
        var isUserMove: Bool = false

        init(_ parent: ChessBoardViewWrapper) {
            self.parent = parent
            super.init()
        }

        @MainActor func chessboardView(_ chessboardView: ChessBoardView,
                                       shouldSelect square: Int,
                                       withCurrentSelection: SelectionContext?) -> SelectionContext? {
            parent.game.chessboardView(chessboardView, shouldSelect: square, selection: withCurrentSelection)
        }

        @MainActor func chessboardView(_ chessboardView: ChessBoardView,
                                       didMovePieceFrom fromSquare: Int,
                                       to toSquare: Int) {
            isUserMove = true
            parent.game.chessboardView(chessboardView, didMovePieceFrom: fromSquare, to: toSquare)
        }

        @MainActor func chessboardView(_ chessboardView: ChessBoardView, pieceFor square: Int) -> Int {
            parent.game.chessboardView(chessboardView, pieceFor: square)
        }
    }
}
