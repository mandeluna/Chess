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
