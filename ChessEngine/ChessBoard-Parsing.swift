//
//  ChessBoard-Parsing.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-15.
//

extension ChessBoard {
    
    // similar to the constructor on ChessMove, but the short form of the notation
    // permits the ASCII name of the piece to be omitted.
    // TODO: It should be easy to internationalize this method & add unicode support
    public func applyMove(san: String) {
        var long_san: String? = nil
        // an awful lot of work just to find out what piece is at the start location
        let short_pattern = /^([abcdefgh])([1-8])-?([abcdefgh])([1-8])(x?)(#?)?$/
        do {
            if  let match = try short_pattern.firstMatch(in: san) {
                let originString = String(match.1) + String(match.2)
                let origin = ChessMove.squareToIndex(originString)
                let black = blackPlayer.piece(at: Int32(origin))
                let white = whitePlayer.piece(at: Int32(origin))
                let code = Int(black + white)
                if let label = ChessMove.BoardCodesToNotation[code] {
                    long_san = label + san
                }
            }
        }
        catch {
            NSLog("unable to match SAN string: \(san)")
            return
        }
        
        let move = if (long_san != nil) { ChessMove(san: long_san!) } else { ChessMove(san: san) }
        self.movePiece(from: move.sourceSquare, to: move.destinationSquare)
    }
    
    /**
     * https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
     *
     * A FEN record contains six fields, each separated by a space. The fields are as follows:
     *
     * 1. Piece placement data: Each rank is described, starting with rank 8 and ending with rank 1, with a "/" between each one;
     *   within each rank, the contents of the squares are described in order from the a-file to the h-file. Each piece is identified
     *   by a single letter taken from the standard English names in algebraic notation (pawn = "P", knight = "N", bishop = "B",
     *   rook = "R", queen = "Q" and king = "K"). White pieces are designated using uppercase letters ("PNBRQKE"), while black
     *   pieces use lowercase letters ("pnbrqk"). A set of one or more consecutive empty squares within a rank is denoted by a digit
     *   from "1" to "8", corresponding to the number of squares.
     *
     * 2. Active color: "w" means that White is to move; "b" means that Black is to move.
     *
     * 3. Castling availability: If neither side has the ability to castle, this field uses the character "-".
     *   Otherwise, this field contains one or more letters: "K" if White can castle kingside, "Q" if White can castle queenside,
     *   "k" if Black can castle kingside, and "q" if Black can castle queenside.
     *   A situation that temporarily prevents castling does not prevent the use of this notation.
     *
     * 4. En passant target square: This is a square over which a pawn has just passed while moving two squares;
     *   it is given in algebraic notation. If there is no en passant target square, this field uses the character "-".
     *   This is recorded regardless of whether there is a pawn in position to capture en passant.
     *   An updated version of the spec has since made it so the target square is recorded only if a legal en passant capture is possible,
     *   but the old version of the standard is the one most commonly used.
     *
     * 5. Halfmove clock: The number of halfmoves since the last capture or pawn advance, used for the fifty-move rule.
     *
     * 6. Fullmove number: The number of the full moves. It starts at 1 and is incremented after Black's move.
     */
    func initializeFromFEN(_ fen: String) {
        let components = fen.split(separator: " ")
        let ranks = String(components[0])
        let color = String(components[1])
        let castling = String(components[2])
        let enpassant = String(components[3])
        let halfmoves: Int32? = Int32(String(components[4]))
        let fullmoves: Int32? = Int32(String(components[5]))
        
        self.initializeFromFEN(
            ranks: ranks,
            color: color,
            castling: castling,
            enpassant: enpassant,
            halfmoves: halfmoves,
            fullmoves: fullmoves)
    }
    
    func initializeFromFEN(ranks: String, color: String?, castling: String?, enpassant: String?, halfmoves: Int32?, fullmoves: Int32?) {
        self.whitePlayer.removeAllPieces()
        self.blackPlayer.removeAllPieces()
        
        initializeRanks(ranks: ranks)
        initializeActiveColor(color: color ?? "w")
        initializeCastling(castling: castling ?? "-")
        initializeEnPassant(enpassant: enpassant ?? "-")
        
        self.halfmoveClock = halfmoves ?? 0
        self.fullmoveNumber = fullmoves ?? 1
    }
    
    func initializeEnPassant(enpassant: String) {
        let enpassant_square = Int32(enpassant)
        if (enpassant == "" || enpassant_square == nil) {
            return
        }
        self.activePlayer.enpassantSquare = enpassant_square!
    }
    
    func initializeCastling(castling: String) {
        if (castling == "-") {
            self.whitePlayer.setCastlingFlags(kCastlingDisableQueenSide)
            self.whitePlayer.setCastlingFlags(kCastlingDisableKingSide)
            self.blackPlayer.setCastlingFlags(kCastlingDisableQueenSide)
            self.blackPlayer.setCastlingFlags(kCastlingDisableKingSide)
        }
        else {
            if (castling.contains("q")) {
                self.blackPlayer.clearCastlingFlags(kCastlingDone | kCastlingDisableQueenSide)
            }
            if (castling.contains("Q")) {
                self.whitePlayer.clearCastlingFlags(kCastlingDone | kCastlingDisableQueenSide)
            }
            if (castling.contains("k")) {
                self.blackPlayer.clearCastlingFlags(kCastlingDone | kCastlingDisableKingSide)
            }
            if (castling.contains("K")) {
                self.whitePlayer.clearCastlingFlags(kCastlingDone | kCastlingDisableKingSide)
            }
        }
    }
    
    func initializeActiveColor(color: String) {
        if (color == "w") {
            self.activePlayer = self.whitePlayer
        }
        else if (color == "b") {
            self.activePlayer = self.blackPlayer
        }
        else {
            NSLog("Invalid color \(color)")
        }
    }
    
    func initializeRanks(ranks: String) {
        let rows = ranks.split(separator: "/")
        var rowIterator = rows.makeIterator()
        for rank in stride(from: 8, to: 0, by: -1) {
            var boardIndex = (rank - 1) * 8
            guard let row = rowIterator.next() else {
                NSLog("Error parsing fen \(ranks): expected more ranks")
                return
            }
            let columns = row.split(separator: "")
            for (_, column) in columns.enumerated() {
                if let numberOfSpaces = Int(String(column)) {
                    boardIndex += numberOfSpaces
                }
                else {
                    let piece = ChessMove.NotationToBoardCodes[String(column).uppercased()]
                    if ["P", "N", "B", "R", "Q", "K"].contains(String(column)) {
                        self.whitePlayer.addPiece(Int32(piece!), at: Int32(boardIndex))
                    }
                    else if ["p", "n", "b", "r", "q", "k"].contains(String(column)) {
                        self.blackPlayer.addPiece(Int32(piece!), at: Int32(boardIndex))
                    }
                    boardIndex += 1
                }
            }
        }
    }
    
    @objc
    public func generateFEN() -> String {
        var fenParts: [String] = []
        
        // 1. Piece placement
        fenParts.append(generatePiecePlacement())
        
        // 2. Active color
        fenParts.append(self.activePlayer == self.whitePlayer ? "w" : "b")
        
        // 3. Castling availability
        fenParts.append(generateCastlingString())
        
        // 4. En passant target square
        fenParts.append(generateEnPassantString())
        
        // 5. Halfmove clock
        fenParts.append("\(halfmoveClock)")
        
        // 6. Fullmove number
        fenParts.append("\(fullmoveNumber)")
        
        return fenParts.joined(separator: " ")
    }
    
    // Gets the board FEN (e.g.``rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR``)
    private func generatePiecePlacement() -> String {
        var ranks: [String] = []
        
        // Process ranks from top (rank 7 = 8th rank) to bottom (rank 0 = 1st rank)
        for rank in (0..<8).reversed() {
            var rankString = ""
            var emptyCount = 0
            
            for file in 0..<8 {
                let index = rank * 8 + file
                
                if let pieceChar = getPieceCharacter(at: Int32(index)) {
                    if emptyCount > 0 {
                        rankString += "\(emptyCount)"
                        emptyCount = 0
                    }
                    rankString += pieceChar
                } else {
                    emptyCount += 1
                }
            }
            
            // Add remaining empty squares at the end of the rank
            if emptyCount > 0 {
                rankString += "\(emptyCount)"
            }
            
            ranks.append(rankString)
        }
        
        return ranks.joined(separator: "/")
    }
    
    private func getPieceCharacter(at index: Int32) -> String? {
        // Check white pieces
        if self.whitePlayer.piece(at: index) > 0 {
            guard let symbol = ChessMove.BoardCodesToNotation[Int(whitePlayer.piece(at: index))] else {
                return nil
            }
            return symbol
        }
        
        // Check black pieces
        if blackPlayer.piece(at: index) > 0 {
            guard let symbol = ChessMove.BoardCodesToNotation[Int(blackPlayer.piece(at: index))] else {
                return nil
            }
            return symbol.lowercased()
        }
        
        return nil // Empty square
    }
    
    private func generateCastlingString() -> String {
        var castling = ""
        
        if generator.canCastleWhiteKingSide() { castling += "K" }
        if generator.canCastleWhiteQueenSide() { castling += "Q" }
        if generator.canCastleBlackKingSide() { castling += "k" }
        if generator.canCastleBlackQueenSide() { castling += "q" }
        
        return castling.isEmpty ? "-" : castling
    }
    
    private func generateEnPassantString() -> String {
        if enpassantSquare == 0 {
            return "-"
        }

        // Convert board coordinates to algebraic notation
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let rankNumber = enpassantSquare % 8 + 1 // Convert 0-7 to 1-8

        // En passant target is always on the 3rd or 6th rank
        return "\(files[Int(enpassantSquare) / 8])\(rankNumber)"
    }

}
