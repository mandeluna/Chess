//
//  ChessGame.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-23.
//

import Foundation
import Combine

struct CapturedPieces {
    var white: [ChessPiece] = []
    var black: [ChessPiece] = []

    private func compressCapturedPieces(_ pieces: [PieceType]) -> [(type: PieceType, count: Int)] {
        let counts = Dictionary(grouping: pieces, by: { $0 }).mapValues { $0.count }
        return counts.map { (type: $0.key, count: $0.value) }
            .sorted { $0.type.value < $1.type.value }
    }

    mutating func append(piece: ChessPiece) {
        if piece.isWhite { white.append(piece) } else { black.append(piece) }
    }

    func compressPieces(isWhite: Bool) -> [(type: PieceType, count: Int)] {
        compressCapturedPieces(isWhite ? white.map(\.type) : black.map(\.type))
    }

    func displayPieces(isWhite: Bool) -> String {
        compressPieces(isWhite: isWhite).map { item in
            item.count > 1 ? "\(item.type.symbol)×\(item.count)" : item.type.symbol
        }.joined(separator: " ")
    }
}

class ChessGame: ObservableObject {
    @Published var pieces: [ChessPiece?] = Array(repeating: nil, count: 64)
    @Published var lastMove: ChessMove? = nil
    @Published var moveHistory: [ChessMove] = []
    @Published var moveHistorySAN: [String] = []
    @Published var capturedPieces = CapturedPieces()
    @Published var kingAttack: ChessMove? = nil
    @Published var statusMessage: String = ""
    @Published var currentPlayer: PieceColor = .white
    @Published var isThinking: Bool = false
    /// True once checkmate, stalemate, or a draw rule has ended the game.
    /// Prevents any further board interaction until a new game is started.
    @Published var isGameOver: Bool = false
    @Published var moveCount: Int = 0
    /// Current search depth reached by the engine (0 when not thinking).
    @Published var thinkingDepth: Int = 0
    /// Principal variation from the current search, as space-separated UCI moves.
    @Published var thinkingLine: String = ""
    /// Engine evaluation in centipawns from white's perspective (positive = white ahead).
    /// Nil until the engine has completed at least one search.
    @Published var engineScore: Int? = nil
    /// Which color the human player controls.
    @Published var humanColor: PieceColor = .white
    /// True when the color-selection overlay should be shown.
    @Published var showColorSelection = false

    /// FEN string for the current board position.
    var currentFEN: String { board.generateFEN() }

    /// True when no moves have been made (board is in starting state or freshly loaded from FEN).
    var isInInitialPosition: Bool { moveHistory.isEmpty }

    /// PGN move list, e.g. "1. e4 e5 2. Nf3 Nc6"
    var pgn: String {
        var result = ""
        var i = 0
        while i < moveHistorySAN.count {
            if i > 0 { result += " " }
            result += "\(i / 2 + 1). \(moveHistorySAN[i])"
            if i + 1 < moveHistorySAN.count {
                result += " \(moveHistorySAN[i + 1])"
            }
            i += 2
        }
        return result
    }

    /// Material score from white's perspective: positive = white ahead, negative = black ahead.
    var score: Int {
        pieces.compactMap { $0 }.reduce(0) { sum, piece in
            sum + (piece.isWhite ? piece.type.value : -piece.type.value)
        }
    }

    private var board: ChessBoard
    private static let savedMovesKey = "savedMoves"
    private static let humanColorKey = "humanColor"

    // Injected after init via attach(settings:)
    private weak var settings: ChessSettings?
    // Tracks the last hash size applied to the engine to avoid redundant reallocations.
    private var appliedHashSizeMB: Int = 0

    init() {
        board = ChessBoard()
        board.initializeSearch()
        board.hasUserAgent = false
        board.initializeNewBoard()
        // Restore color preference before replaying moves so triggerEngineIfNeeded works.
        if UserDefaults.standard.string(forKey: Self.humanColorKey) == "black" {
            humanColor = .black
        }
        restoreGame()
    }

    /// Called by ShambolicApp once both state objects exist. Sets the settings reference
    /// and applies the initial hash size to the engine.
    func attach(settings: ChessSettings) {
        self.settings = settings
        let mb = settings.hashSizeMB
        board.searchAgent.setHashSizeMB(Int32(mb))
        appliedHashSizeMB = mb
    }

    func resetGame() {
        board.searchAgent.cancelSearch()
        board.initializeSearch()
        board.hasUserAgent = false
        board.initializeNewBoard()
        clearGameState()
        refreshFromBoard()
        showColorSelection = true
    }

    /// Load a position from a FEN string, discarding the current game.
    func loadFEN(_ fen: String) {
        board.searchAgent.cancelSearch()
        board.initializeSearch()
        board.hasUserAgent = false
        board.initialize(fromFEN: fen)
        clearGameState()
        refreshFromBoard()
        triggerEngineIfNeeded()
    }

    /// Called by the color-selection overlay; saves preference and starts the game.
    func setHumanColor(_ color: PieceColor) {
        humanColor = color
        UserDefaults.standard.set(color == .black ? "black" : "white", forKey: Self.humanColorKey)
        showColorSelection = false
        triggerEngineIfNeeded()
    }

    private func clearGameState() {
        moveHistory = []
        moveHistorySAN = []
        capturedPieces = CapturedPieces()
        kingAttack = nil
        lastMove = nil
        isThinking = false
        isGameOver = false
        moveCount = 0
        engineScore = nil
        thinkingDepth = 0
        thinkingLine = ""
        UserDefaults.standard.removeObject(forKey: Self.savedMovesKey)
    }

    /// Called on a background thread by the engine after each depth iteration.
    private func handleEngineUpdate(_ info: NSDictionary) {
        let depth = (info["depth"] as? Int) ?? 0
        let pv = (info["pv"] as? [String]) ?? []
        let line = pv.prefix(8).joined(separator: " ")
        let cp = ((info["score"] as? [String: Any])?["cp"] as? Int)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.thinkingDepth = depth
            self.thinkingLine = line
            if let cp { self.engineScore = -cp }
        }
    }

    /// Returns true when it is the engine's turn to move.
    private var isEngineTurn: Bool {
        humanColor == .white ? currentPlayer == .black : currentPlayer == .white
    }

    /// Trigger the engine to search if it is the engine's turn and no search is running.
    private func triggerEngineIfNeeded() {
        guard isEngineTurn, !isThinking else { return }
        startEngineSearch()
    }

    /// Start an engine search using the current settings. Runs the search on a background
    /// queue and calls applyEngineMove on the main queue when complete.
    private func startEngineSearch() {
        guard board.searchAgent.isReady() else { return }
        isThinking = true
        thinkingDepth = 0
        thinkingLine = ""
        board.searchAgent.setActivePlayer(board.activePlayer)

        // Apply hash size if it has changed since last search.
        let hashMB = settings?.hashSizeMB ?? 128
        if hashMB != appliedHashSizeMB {
            board.searchAgent.setHashSizeMB(Int32(hashMB))
            appliedHashSizeMB = hashMB
        }

        let params = settings?.uciSearchParams ?? ["movetime": 5000]

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            autoreleasepool {
                guard let self else { return }
                self.board.searchAgent.performSearch(
                    withUCIParams: params,
                    updateCallback: { [weak self] info in
                        guard let info else { return }
                        self?.handleEngineUpdate(info as NSDictionary)
                    },
                    completionCallback: { [weak self] info, _ in
                        let move = info?["bestmove"] as? String
                        DispatchQueue.main.async { self?.applyEngineMove(move) }
                    }
                )
            }
        }
    }

    // MARK: - Board view delegate interface

    @MainActor
    func chessboardView(_ chessboardView: ChessBoardView, shouldSelect square: Int, selection: SelectionContext?) -> SelectionContext? {
        guard board.searchAgent.isReady(), !isThinking, !isGameOver else { return nil }
        let candidate = chessboardView.selectionInfo(for: square)
        guard let candidate = candidate else { return nil }
        if selection?.square == candidate.square { return nil }
        let piece = board.activePlayer.piece(at: Int32(square))
        guard piece > 0 else { return nil }
        candidate.moves = board.activePlayer.findValidMoves(at: Int32(square)) as? [ChessMove] ?? []
        candidate.captures = captureSquares()
        return candidate
    }

    func chessboardView(_ chessboardView: ChessBoardView, didMovePieceFrom fromSquare: Int, to toSquare: Int) {
        guard board.searchAgent.isReady(), !isThinking, !isGameOver else { return }
        applyUserMove(from: fromSquare, to: toSquare)
    }

    func chessboardView(_ chessboardView: ChessBoardView, pieceFor square: Int) -> Int {
        return Int(board.activePlayer.piece(at: Int32(square)))
    }

    // MARK: - Move application

    private func applyUserMove(from fromSquare: Int, to toSquare: Int) {
        guard let move = findMove(from: fromSquare, to: toSquare) else { return }

        let gameOver = apply(move: move)
        guard !gameOver else { return }

        startEngineSearch()
    }

    private func applyEngineMove(_ uciMove: String?) {
        isThinking = false
        thinkingDepth = 0
        thinkingLine = ""

        // Capture the engine's evaluation before the move is applied.
        // myMove.value is from the searching player's (engine/black) perspective; negate for white.
        if let myMove = board.searchAgent.myMove {
            engineScore = -Int(myMove.value)
        }

        guard let uciMove = uciMove, !uciMove.isEmpty,
              let (from, to, promo) = parseUCI(uciMove),
              let move = findMove(from: from, to: to, promotionPiece: promo) else {
            refreshFromBoard()
            return
        }
        apply(move: move)
    }

    /// Apply a move: record SAN, execute on board, track history, refresh UI state.
    /// Returns true if the game is over after this move.
    @discardableResult
    private func apply(move: ChessMove) -> Bool {
        // SAN must be computed before nextMove (board state reflects pre-move position)
        let san = move.sanString(for: board)

        board.nextMove(move)

        // After nextMove, activePlayer is the next player.
        // The captured piece (if any) belonged to the now-active player.
        if move.capturedPiece != 0 {
            let captured = ChessPiece(
                piece: move.capturedPiece,
                square: Int(move.destinationSquare),
                isWhite: board.activePlayer.isWhitePlayer()
            )
            capturedPieces.append(piece: captured)
        }

        moveHistorySAN.append(san)
        moveHistory.append(move)
        lastMove = move
        moveCount += 1
        saveGame()

        return refreshFromBoard()
    }

    // MARK: - State refresh

    /// Rebuild all published state from the board. Returns true if the game is over.
    @discardableResult
    private func refreshFromBoard() -> Bool {
        pieces = piecesFromBoard()
        currentPlayer = board.activePlayer == board.whitePlayer ? .white : .black

        // findValidMoves internally calls the move generator, which sets
        // generator.kingAttack when the active player's king is under attack.
        // Reading kingAttack immediately after avoids a second generator pass.
        let validMoves = board.activePlayer.findValidMoves()
        kingAttack = board.generator.kingAttack

        let noMoves = validMoves == nil || validMoves!.isEmpty

        if noMoves {
            statusMessage = kingAttack != nil ? "Checkmate" : "Stalemate"
            board.searchAgent.cancelSearch()
            isGameOver = true
            return true
        }
        if board.halfmoveClock >= 100 {
            statusMessage = "Draw (50-move rule)"
            board.searchAgent.cancelSearch()
            isGameOver = true
            return true
        }
        statusMessage = currentPlayer == .white ? "White to move" : "Black to move"
        return false
    }

    private func piecesFromBoard() -> [ChessPiece?] {
        (0..<64).map { square in
            let wp = board.whitePlayer.piece(at: Int32(square))
            if wp > 0 { return ChessPiece(piece: wp, square: square, isWhite: true) }
            let bp = board.blackPlayer.piece(at: Int32(square))
            if bp > 0 { return ChessPiece(piece: bp, square: square, isWhite: false) }
            return nil
        }
    }

    // MARK: - Persistence

    private func saveGame() {
        let uciMoves = moveHistory.map { $0.uciString() }
        UserDefaults.standard.set(uciMoves, forKey: Self.savedMovesKey)
    }

    /// Replay saved UCI moves at startup. Rebuilds all state without triggering
    /// per-move UI refreshes. Falls back to a fresh board if any move is invalid.
    private func restoreGame() {
        guard let uciMoves = UserDefaults.standard.stringArray(forKey: Self.savedMovesKey),
              !uciMoves.isEmpty else {
            refreshFromBoard()
            showColorSelection = true
            return
        }

        var restored = true
        for uci in uciMoves {
            guard let (from, to, promo) = parseUCI(uci),
                  let move = findMove(from: from, to: to, promotionPiece: promo) else {
                // Saved state is corrupt — start fresh rather than leaving a half-replayed position.
                board.initializeNewBoard()
                moveHistory = []
                moveHistorySAN = []
                capturedPieces = CapturedPieces()
                lastMove = nil
                moveCount = 0
                UserDefaults.standard.removeObject(forKey: Self.savedMovesKey)
                restored = false
                break
            }

            let san = move.sanString(for: board)
            board.nextMove(move)

            if move.capturedPiece != 0 {
                let captured = ChessPiece(
                    piece: move.capturedPiece,
                    square: Int(move.destinationSquare),
                    isWhite: board.activePlayer.isWhitePlayer()
                )
                capturedPieces.append(piece: captured)
            }

            moveHistorySAN.append(san)
            moveHistory.append(move)
            lastMove = move
            moveCount += 1
        }

        refreshFromBoard()

        if restored {
            // If the engine is next to move (e.g. app killed mid-turn), resume the search.
            triggerEngineIfNeeded()
        } else {
            showColorSelection = true
        }
    }

    // MARK: - Move lookup (ObjC API, no ChessEngine Swift extensions needed)

    /// Find a legal move for the current active player from source to destination.
    /// Optionally matches a specific promotion piece (kQueen, kRook, etc.).
    private func findMove(from fromSquare: Int, to toSquare: Int, promotionPiece: Int32? = nil) -> ChessMove? {
        guard let moves = board.activePlayer.findPossibleMoves(at: Int32(fromSquare)) as? [ChessMove] else { return nil }
        for move in moves {
            guard Int(move.destinationSquare) == toSquare else { continue }
            if let promo = promotionPiece {
                if move.promotion() == promo { return move }
                continue
            }
            return move
        }
        return nil
    }

    /// Parse a UCI move string ("e2e4", "e7e8q") into board square indices.
    private func parseUCI(_ uci: String) -> (from: Int, to: Int, promotion: Int32?)? {
        let chars = Array(uci.lowercased())
        guard chars.count >= 4 else { return nil }
        let files = "abcdefgh"
        guard let f1 = files.firstIndex(of: chars[0]),
              let r1 = Int(String(chars[1])), (1...8).contains(r1),
              let f2 = files.firstIndex(of: chars[2]),
              let r2 = Int(String(chars[3])), (1...8).contains(r2) else { return nil }
        let from = (r1 - 1) * 8 + files.distance(from: files.startIndex, to: f1)
        let to   = (r2 - 1) * 8 + files.distance(from: files.startIndex, to: f2)
        let promotionMap: [Character: Int32] = [
            "q": Int32(kQueen), "r": Int32(kRook), "b": Int32(kBishop), "n": Int32(kKnight)
        ]
        let promo = chars.count > 4 ? promotionMap[chars[4]] : nil
        return (from, to, promo)
    }

    // MARK: - Helpers

    private func captureSquares() -> [Int] {
        guard let moves = board.activePlayer.findPossibleMoves() as? [ChessMove] else { return [] }
        return moves.filter { $0.capturedPiece != 0 }.map { Int($0.destinationSquare) }
    }
}
