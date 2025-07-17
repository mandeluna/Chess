//
//  ChessMove-Parsing.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-16.
//

extension ChessMove {
  
  public static let NotationToBoardCodes = [
    "P" : kPawn, "N" : kKnight, "B" : kBishop, "R" : kRook, "Q" : kQueen, "K" : kKing
  ]
  
  /**
   * https://en.wikipedia.org/wiki/Universal_Chess_Interface
   *
   * In long algebraic notation, also known as fully expanded algebraic notation, both the starting and ending squares are specified, for example: e2e4.
   * Sometimes these are separated by a hyphen, e.g. Nb1-c3, while captures are indicated by an "x", e.g. Rd3xd7.
   *
   * A form of long algebraic notation (without piece names) is also used by the Universal Chess Interface (UCI) standard, which is a common way
   * for graphical chess programs to communicate with chess engines, e.g. e2e4, e1g1 (castling), e7e8q (promotion).
   *
   * This spec is somewhat vague about whether notation for piece names is provided (internationalization could be an issue).
   *
   *** The argument should be five or six characters in length, e.g. Ne4d6
   *** * You must specify the piece name (uppercase ASCII PNBRQK) because ChessMove does not maintain a board representation
   *** * Do not specify indications of capture, check, or checkmate.
   *** * A promotion character (ASCII QRBN) may be appended if the move is a pawn reaching the opponent's starting rank (default Q)
   */
  convenience init(uci: String) {
    self.init()
    let chars = uci.split(separator: "")
    var charIterator = chars.makeIterator()
    let notated_piece = String(charIterator.next()!)
    let start_rank = (charIterator.next()?.unicodeScalars.first!.value ?? 49) - 49
    let start_file = (charIterator.next()?.unicodeScalars.first!.value ?? 49) - 49
    let end_rank = (charIterator.next()?.unicodeScalars.first!.value ?? 97) - 97
    let end_file = (charIterator.next()?.unicodeScalars.first!.value ?? 97) - 97
    let movingPiece = Int32(Self.NotationToBoardCodes[notated_piece]!)
    let start = start_rank * 8 + start_file
    let end = end_rank * 8 + end_file
    self.move(movingPiece, from: Int32(start), to: Int32(end))
  }
  
  convenience init(piece: Int32, start: Int32, end: Int32) {
    self.init()
    self.move(piece, from: start, to: end)
  }
  
  class func squareToIndex(_ square: String) -> UInt32 {
    let file = square.unicodeScalars.first!.value - 97
    let rank = square.unicodeScalars.last!.value - 49
    return rank * 8 + file
  }
}
