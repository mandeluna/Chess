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
        context.coordinator.view = view
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.updateBoard(game.pieces)
    }
    
    class Coordinator: NSObject, @MainActor ChessBoardViewDelegate {
        @MainActor func chessboardView(_ chessboardView: ChessBoardView, shouldSelect square: Int, withCurrentSelection: SelectionContext?) -> SelectionContext? {
            return parent.game.chessboardView(chessboardView, shouldSelect: square, selection: withCurrentSelection)
        }
        
        @MainActor func chessboardView(_ chessboardView: ChessBoardView, didMovePieceFrom fromSquare: Int, to toSquare: Int) {
            return parent.game.chessboardView(chessboardView, didMovePieceFrom: fromSquare, to: toSquare)
        }
        
        @MainActor func chessboardView(_ chessboardView: ChessBoardView, pieceFor square: Int) -> Int {
            return parent.game.chessboardView(chessboardView, pieceFor: square)
        }
        
        var parent: ChessBoardViewWrapper
        weak var view: UIViewType?

        init(_ parent: ChessBoardViewWrapper) {
            self.parent = parent
            super.init()
        }
    }
}
