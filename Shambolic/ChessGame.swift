//
//  ChessGame.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-23.
//

import Foundation
import Combine

typealias PieceDescription = [String:Any]

struct CapturedPieces {
    var white: [ChessPiece] = []
    var black:[ChessPiece] = []
    
    private func compressCapturedPieces(_ pieces: [PieceType]) -> [(type: PieceType, count: Int)] {
        // Count occurrences of each piece type
        let counts = Dictionary(grouping: pieces, by: { $0 })
            .mapValues { $0.count }
        
        // Convert to array and sort by piece value
        return counts.map { (type: $0.key, count: $0.value) }
            .sorted { $0.type.value < $1.type.value }
    }

    private func displayCompressedPieces(_ compressed: [(type: PieceType, count: Int)], isWhite: Bool) -> String {
        compressed.map { item in
            if item.count > 1 {
                return "\(item.type.symbol)×\(item.count)"
            } else {
                return item.type.symbol
            }
        }.joined(separator: " ")
    }
    
    mutating func append(piece: ChessPiece) {
        if piece.isWhite {
            white.append(piece)
        }
        else {
            black.append(piece)
        }
    }

    func displayPieces(isWhite: Bool) -> String {
        let compressed = compressCapturedPieces(isWhite ? white.map(\.type) : black.map(\.type))
        return displayCompressedPieces(compressed, isWhite: isWhite)
    }

    func compressPieces(isWhite: Bool) -> [(type: PieceType, count: Int)] {
        return compressCapturedPieces(isWhite ? white.map(\.type) : black.map(\.type))
    }
}

class ChessGame: ObservableObject {
    @Published var pieces: [ChessPiece?] = Array(repeating: nil, count: 64)
    @Published var lastMove: ChessMove? = nil
    @Published var moveHistory: [ChessMove] = []
    @Published var capturedPieces = CapturedPieces()
    @Published var kingAttack: ChessMove? = nil
    @Published var statusMessage: String = ""
    @Published var analysis: LichessAnalysis? = nil
    @Published var currentPlayer: PieceColor = .white
    @Published var showLegalMoves: Bool = true
    @Published var highlightChecks: Bool = true
    @Published var moveTime: Double = 0.0
    
    private var board: ChessBoard
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        board = ChessBoard()
        initializeBoardObservers()
        initializeGameState()
    }
    
    public func resetGame() {
        board.initializeSearch()
        board.initializeNewBoard()
        moveHistory = []
        kingAttack = nil
        capturedPieces = CapturedPieces()
        updateStatusMessage(isWhite:true)
    }

    public func undoLastMove() {
        if !moveHistory.isEmpty {
            let move = moveHistory.removeLast()
            board.undoMove(move)
        }
    }

    public func showAnalysis() {
    }

    public func capturedPieces(for color: PieceColor) -> [ChessPiece] {
        switch color {
            case .black: return capturedPieces.black
            case .white: return capturedPieces.white
        }
    }
    
    @MainActor public func chessboardView(_ chessboardView: ChessBoardView, shouldSelect square: Int, selection: SelectionContext?) -> SelectionContext? {
        if !board.searchAgent.isReady() {
            return nil
        }

        let candidate = chessboardView.selectionInfo(for: square)

        // if we have a current selection, this is a destination selection attempt
        if selection?.square == candidate?.square {
            return nil
        }

        // no current selection -- this is a piece selection attempt
        let piece = board.activePlayer.piece(at:Int32(square))

        if (piece <= 0) {
            return nil
        }

        candidate?.moves = board.activePlayer.findValidMoves(at:Int32(square)) as? [ChessMove] ?? []
        candidate?.captures = captureSquares()

        return candidate
    }

    func chessboardView(_ chessboardView: ChessBoardView, didMovePieceFrom fromSquare: Int, to toSquare: Int) {
        if !board.searchAgent.isReady() {
            return
        }

        board.movePiece(from:Int32(fromSquare), to:Int32(toSquare))
        board.searchAgent.startSearchThread()
    }

    func chessboardView(_ chessboardView: ChessBoardView, pieceFor square: Int) -> Int {
        return Int(board.activePlayer.piece(at: Int32(square)))
    }
    
    private func captureSquares() -> [Int] {
        let moves : [ChessMove?] = board.activePlayer.findPossibleMoves() as! [ChessMove?]
        return moves
            .filter { $0!.capturedPiece != 0 }
            .compactMap { Int($0!.destinationSquare) } as [Int]
    }

    private func initializeBoardObservers() {
        let handlers : [String:([String:Any])->Void] = [
            "AddedPiece" : { [weak self] dictionary in self?.handleAddedPiece(dictionary: dictionary) },
            "CompletedMove" : { [weak self] dictionary in self?.handleCompletedMove(dictionary: dictionary) },
            "MovedPiece" : { [weak self] dictionary in self?.handleMovedPiece(dictionary: dictionary) },
            "RemovedPiece" : { [weak self] dictionary in self?.handleRemovedPiece(dictionary: dictionary) },
            "ReplacedPiece" : { [weak self] dictionary in self?.handleReplacedPiece(dictionary: dictionary) },
            "FinishedGame" : { [weak self] dictionary in self?.handleFinishedGame(dictionary: dictionary) },
            "UndoMove" : { [weak self] dictionary in self?.handleUndoMove(dictionary: dictionary) },
            "StartedThinking" : { [weak self] dictionary in self?.handleSearchStarted(dictionary: dictionary) },
            "StoppedThinking" : { [weak self] dictionary in self?.handleSearchCompleted(dictionary: dictionary) }
        ]
        for handler in handlers {
            NotificationCenter.default.publisher(for: Notification.Name(handler.key))
                .compactMap { $0.object as? PieceDescription }
                .sink { dictionary in handler.value(dictionary) }
                .store(in: &cancellables)
        }
    }
    
    private func handleAddedPiece(dictionary: PieceDescription) {
        guard let piece = dictionary["piece"] as? Int32,
              let square = dictionary["square"] as? Int,
              let white = dictionary["white"] as? Bool else { return }
        
        pieces[square] = ChessPiece(piece: piece, square: square, isWhite: white)
    }
    
    private func handleCompletedMove(dictionary: PieceDescription) {
        guard let move = dictionary["move"] as? ChessMove,
              let white = dictionary["white"] as? Bool else { return }
        
        moveHistory.append(move)

        // TODO: update king attack indicator
        kingAttack = findKingAttack()

        updateStatusMessage(isWhite: white)
    }

    private func handleMovedPiece(dictionary: PieceDescription) {
        guard let from = dictionary["from"] as? Int,
              let to = dictionary["to"] as? Int else { return }
        
        let piece = pieces[from]
        pieces[from] = nil
        pieces[to] = piece
    }

    private func handleRemovedPiece(dictionary: PieceDescription) {
        guard let _ = dictionary["piece"] as? Int,
              let square = dictionary["square"] as? Int else { return }
        
        if let piece = pieces[square] {
            piece.isWhite ? capturedPieces.white.append(piece) : capturedPieces.black.append(piece)
            pieces[square] = nil
        }
    }

    // handle promotion of pawn
    private func handleReplacedPiece(dictionary: PieceDescription) {
        guard let _ = dictionary["old"] as? Int,
              let new = dictionary["new"] as? Int32,
              let square = dictionary["square"] as? Int,
              let white = dictionary["white"] as? Bool else { return }
        
        pieces[square] = ChessPiece(piece: new, square: square, isWhite: white)
    }

    // resign or stalemate coming from engine (not sure if there is a hook for this)
    private func handleFinishedGame(dictionary: PieceDescription) {
        let stalemate = dictionary["stalemate"] as? Bool
        let white = dictionary["white"] as? Bool

        let playerString = white! ? "White" : "Black"
        statusMessage = playerString + " " + (stalemate == nil ? "Resigns" : "Stalemate")
    }
    
    private func handleUndoMove(dictionary: PieceDescription) {
        // notifications for undo will come from ChessPlayer>>undoMove
        // TODO: board move counters and timers will be all messed up -- we should replay the board from the beginning of the list
    }
    
    private func handleSearchStarted(dictionary: PieceDescription) {
    }
    
    private func handleSearchCompleted(dictionary: PieceDescription) {
        let encodedMove = dictionary["bestmove"] as? Int

        if encodedMove == nil {
            statusMessage = dictionary["reason"] as? String ?? "No move found"
            board.searchAgent.cancelSearch()
            return
        }

        let isWhite = board.activePlayer == board.whitePlayer
        let move = ChessMove.decode(from: Int32(encodedMove!))
        let square = Int(move.destinationSquare)

        if let piece = pieces[square] {
            capturedPieces.append(piece: piece)
        }

        pieces[Int(move.sourceSquare)] = nil
        pieces[square] = ChessPiece(piece: move.movingPiece, square: square, isWhite: isWhite)
    }
    
    private func updateStatusMessage(isWhite: Bool) {
        let whiteMoves = board.whitePlayer.findValidMoves()
        let blackMoves = board.blackPlayer.findValidMoves()
        let moves = board.activePlayer == board.whitePlayer ? whiteMoves : blackMoves
        
        // no moves for the active player (findValidMoves returns an empty array, but findPossibleMoves returns nil)
        if moves == nil || moves!.isEmpty {
            statusMessage = kingAttack != nil ? "Checkmate" : "Stalemate"   // current player is not in check, but is unable to move
            board.searchAgent.cancelSearch()
        }
        else if board.halfmoveClock >= 100 {
            statusMessage = "Draw (50 move rule)"   // 100 halfmoves without a pawn move or a capture
            board.searchAgent.cancelSearch()
        }
        else {
            statusMessage = isWhite ? "White's move" : "Black's move"
        }

    }
    
    private func findKingAttack() -> ChessMove? {
        let _ = board.whitePlayer.findPossibleMoves()
        if board.generator.kingAttack != nil {
            return board.generator.kingAttack
        }
        let _ = board.blackPlayer.findPossibleMoves()
        return board.generator.kingAttack
    }
    
    private func initializeGameState() {
        board.resetGame()
        board.hasUserAgent = true
        board.initializeSearch()
        board.initializeNewBoard()
    }
}
