//
//  ChessBoard-Parsing.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-15.
//

extension ChessBoard {
  func initializeFromFEN(_ fen: String) {
    self.whitePlayer.removeAllPieces()
    self.blackPlayer.removeAllPieces()
    let rows = fen.split(separator: "/")
    var boardIndex = 0
    for row in rows {
      let columns = row.split(separator: "")
      for (_, column) in columns.enumerated() {
        if let numberOfSpaces = Int(String(column)) {
          boardIndex += numberOfSpaces
        }
        else {
          var player: ChessPlayer?
          var piece: Int?
          switch column {
            // white pieces
          case "P":
            player = self.whitePlayer
            piece = kPawn
            break
          case "N":
            player = self.whitePlayer
            piece = kKnight
            break
          case "B":
            player = self.whitePlayer
            piece = kBishop
            break
          case "R":
            player = self.whitePlayer
            piece = kRook
            break
          case "Q":
            player = self.whitePlayer
            piece = kQueen
            break
          case "K":
            player = self.whitePlayer
            piece = kKing
            break
            // black pieces
          case "p":
            player = self.blackPlayer
            piece = kPawn
            break
          case "n":
            player = self.blackPlayer
            piece = kKnight
            break
          case "b":
            player = self.blackPlayer
            piece = kBishop
            break
          case "r":
            player = self.blackPlayer
            piece = kRook
            break
          case "q":
            player = self.blackPlayer
            piece = kQueen
            break
          case "k":
            player = self.blackPlayer
            piece = kKing
            break
          default:
            break
          }
          if player != nil && piece != nil {
            player!.addPiece(Int32(piece!), at: Int32(boardIndex))
            boardIndex += 1
          }
        }
      }
    }
  }
}
