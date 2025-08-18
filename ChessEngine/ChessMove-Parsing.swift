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
  
  public static let BoardCodesToNotation = [
    kPawn: "P", kKnight: "N", kBishop: "B", kRook: "R", kQueen: "Q", kKing: "K"
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
  convenience init(san: String) {
    self.init()
    
    let san_pattern = /([PQKNRB])?([abcdefgh])([1-8])-?([abcdefgh])([1-8])(x?)(#?)?/
    do {
      guard
        let match = try san_pattern.firstMatch(in: san)
          
      else {
        NSLog("invalid SAN string: \(san)")
        return
      }
      let start_file = String(match.2)  // a-h
      let start_rank = UInt32(match.3)!  // 1-8
      let end_file = String(match.4)
      let end_rank = UInt32(match.5)!
      
      let start = (start_rank - 1) * 8 + start_file.unicodeScalars.first!.value - 97
      let end = (end_rank - 1) * 8 + end_file.unicodeScalars.first!.value - 97
      if (match.1 != nil) {
          let notated_piece = String(match.1!) // PQKNRB
          self.movingPiece = Int32(Self.NotationToBoardCodes[String(notated_piece)]!)
          self.move(movingPiece, from: Int32(start), to: Int32(end))
      }
      else {
        self.move(-1, from: Int32(start), to: Int32(end))
      }
    }
    catch {
      NSLog("Unable to match SAN string: \(san)")
      return
    }
  }
  
  convenience init(piece: Int32, start: Int32, end: Int32) {
    self.init()
    self.move(piece, from: start, to: end)
  }
  
  class func squareToIndex(_ square: String) -> UInt32 {
    if (square.count != 2) {
      print("Invalid square string: \(square)")
    }
    let file = square.unicodeScalars.first!.value - 97
    let rank = square.unicodeScalars.last!.value - 49
    return rank * 8 + file
  }
  
  class func squareToIndex(_ square: String, from: Int, to: Int) -> UInt32 {
    let startIndex = square.index(square.startIndex, offsetBy: from)
    let endIndex = square.index(square.startIndex, offsetBy: to)
    let range = startIndex ..< endIndex
    return squareToIndex(String(square[range]))
  }
  
}
