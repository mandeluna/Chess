//
//  ChessPiece.swift
//  Chess
//
//  Created by Steve Wart on 2025-09-25.
//

import Foundation

enum PieceType: Int32 {
    case unknown = -1, empty, pawn, knight, bishop, rook, queen, king
    var value: Int {
        switch self {
        case .pawn: return 1
        case .knight: return 3
        case .bishop: return 3
        case .rook: return 5
        case .queen: return 9
        case .king: return 0    // kings aren't captured
        default: return 0
        }
    }

    // return only filled symbols
    var symbol: String {
        switch self {
        case .pawn: return "♟"
        case .knight: return "♞"
        case .bishop: return "♝"
        case .rook: return "♜"
        case .queen: return "♛"
        case .king: return "♚"
        default: return ""
        }
    }
}

struct ChessPiece: Equatable, Hashable {
    var piece: Int32
    var square: Int
    var isWhite: Bool
    var type: PieceType
    
    init(piece: Int32, square: Int, isWhite: Bool) {
        self.piece = piece
        self.square = square
        self.isWhite = isWhite
        self.type = PieceType(rawValue: piece) ?? PieceType.unknown
    }
    
    init(type: PieceType, square: Int, isWhite: Bool) {
        self.piece = type.rawValue
        self.square = square
        self.isWhite = isWhite
        self.type = type
    }

    var symbol: String {
        switch type {
        case .pawn: return isWhite ? "♙" : "♟"
        case .knight: return isWhite ? "♘" : "♞"
        case .bishop: return isWhite ? "♗" : "♝"
        case .rook: return isWhite ? "♖" : "♜"
        case .queen: return isWhite ? "♕" : "♛"
        case .king: return isWhite ? "♔" : "♚"
        default: return ""
        }
    }
}

enum PieceColor {
    case black, white
}

