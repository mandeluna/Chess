//
//  Move.swift
//  ChessEngine
//
//  A compact value-type move representation.
//  Stores all move data in a single UInt64 — no heap allocation, no reference
//  counting, no copyWithZone:
//
//  Bit layout:
//    bits  0– 5   to           destination square (0–63)
//    bits  6–11   from         source square (0–63)
//    bits 12–14   piece        moving piece (Piece raw value, 1–6)
//    bits 15–17   captured     captured piece (0 = none, 1–6)
//    bits 18–20   promotion    promoted-to piece (0 = none, 2–5)
//    bits 21–24   kind         Kind raw value (0–15)
//    bits 25–40   score        move-ordering score (Int16 bit-pattern)
//    bits 41–63   (reserved)
//

public struct Move: Equatable, Hashable, Sendable {

    // MARK: - Nested types

    /// The six piece types, matching the ObjC kPawn…kKing constants.
    public enum Piece: Int {
        case pawn   = 1
        case knight = 2
        case bishop = 3
        case rook   = 4
        case queen  = 5
        case king   = 6
    }

    /// What kind of move this is.  Stored in 4 bits, so values 0–15 are valid;
    /// the engine currently uses 0–7.
    public enum Kind: UInt64 {
        case null            = 0
        case normal          = 1  // quiet move or capture
        case doublePush      = 2  // pawn two-square advance; sets the en-passant square
        case enPassant       = 3  // en-passant capture
        case castleKingside  = 4
        case castleQueenside = 5
        case resign          = 6  // game-over: in check, no legal moves
        case stalemate       = 7  // game-over: not in check, no legal moves
    }

    // MARK: - Raw storage

    public let bits: UInt64

    // MARK: - Field accessors
    //
    // Every accessor compiles to a single shift-and-mask instruction.
    // The compiler inlines them at every call site.

    public var to:        Int   { Int(bits)       & 0x3F }
    public var from:      Int   { Int(bits >>  6) & 0x3F }
    public var piece:     Int   { Int(bits >> 12) & 0x07 }
    public var captured:  Int   { Int(bits >> 15) & 0x07 }
    public var promotion: Int   { Int(bits >> 18) & 0x07 }
    public var kind:      Kind  { Kind(rawValue: (bits >> 21) & 0x0F) ?? .normal }
    public var score:     Int16 { Int16(bitPattern: UInt16((bits >> 25) & 0xFFFF)) }

    // MARK: - Predicates

    public var isNull:      Bool { bits == 0 }
    public var isCapture:   Bool { captured != 0 }
    public var isPromotion: Bool { promotion != 0 }
    public var isCastle:    Bool { kind == .castleKingside || kind == .castleQueenside }
    public var isTerminal:  Bool { kind == .resign || kind == .stalemate }

    // MARK: - Null move

    /// The null-move sentinel.  bits == 0, kind == .null, isNull == true.
    public static let null = Move(bits: 0)

    // MARK: - Factories

    public static func move(piece: Int, from: Int, to: Int, captured: Int = 0) -> Move {
        Move(bits: _pack(to: to, from: from, piece: piece,
                         captured: captured, kind: .normal))
    }

    public static func doublePush(piece: Int, from: Int, to: Int) -> Move {
        Move(bits: _pack(to: to, from: from, piece: piece, kind: .doublePush))
    }

    public static func enPassant(piece: Int, from: Int, to: Int, captured: Int) -> Move {
        Move(bits: _pack(to: to, from: from, piece: piece,
                         captured: captured, kind: .enPassant))
    }

    public static func castleKingside(piece: Int, from: Int, to: Int) -> Move {
        Move(bits: _pack(to: to, from: from, piece: piece, kind: .castleKingside))
    }

    public static func castleQueenside(piece: Int, from: Int, to: Int) -> Move {
        Move(bits: _pack(to: to, from: from, piece: piece, kind: .castleQueenside))
    }

    /// `piece` is always kPawn (1); `promoteTo` is kKnight…kQueen (2–5).
    public static func promotion(piece: Int, from: Int, to: Int,
                                 promoteTo: Int, captured: Int = 0) -> Move {
        Move(bits: _pack(to: to, from: from, piece: piece,
                         captured: captured, promotion: promoteTo, kind: .normal))
    }

    public static func resign(piece: Int) -> Move {
        Move(bits: _pack(piece: piece, kind: .resign))
    }

    public static func stalemate(piece: Int) -> Move {
        Move(bits: _pack(piece: piece, kind: .stalemate))
    }

    // MARK: - Score

    /// Returns a copy of this move with `score` replaced.  The board-level
    /// identity (from/to/piece/etc.) is unchanged.
    public func withScore(_ s: Int16) -> Move {
        let mask: UInt64 = 0xFFFF << 25
        return Move(bits: (bits & ~mask) | UInt64(UInt16(bitPattern: s)) << 25)
    }

    // MARK: - Equatable / Hashable
    //
    // Two moves are equal when they describe the same board action.
    // The ordering score (bits 25–40) is intentionally excluded so that
    // a freshly generated move and the same move retrieved from the
    // transposition table compare equal regardless of their scores.

    public static func == (lhs: Move, rhs: Move) -> Bool {
        (lhs.bits & Self.identityMask) == (rhs.bits & Self.identityMask)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bits & Self.identityMask)
    }

    // MARK: - UCI output

    /// Long-algebraic UCI notation: "e2e4", "g7f8q", "0000" for the null move.
    public var uciString: String {
        if isNull { return "0000" }
        var bytes: [UInt8] = [
            0x61 + UInt8(from & 7),   // 'a' + file
            0x31 + UInt8(from >> 3),  // '1' + rank
            0x61 + UInt8(to   & 7),
            0x31 + UInt8(to   >> 3),
        ]
        switch promotion {
        case 2: bytes.append(0x6E)  // 'n'
        case 3: bytes.append(0x62)  // 'b'
        case 4: bytes.append(0x72)  // 'r'
        case 5: bytes.append(0x71)  // 'q'
        default: break
        }
        return String(bytes: bytes, encoding: .ascii) ?? "????"
    }

    // MARK: - Private

    /// Bits covering board-level identity (everything except the score).
    private static let identityMask: UInt64 = (1 << 25) - 1

    private static func _pack(to: Int = 0, from: Int = 0, piece: Int = 0,
                               captured: Int = 0, promotion: Int = 0,
                               kind: Kind) -> UInt64 {
          (UInt64(to)        & 0x3F)
        | (UInt64(from)      & 0x3F) << 6
        | (UInt64(piece)     & 0x07) << 12
        | (UInt64(captured)  & 0x07) << 15
        | (UInt64(promotion) & 0x07) << 18
        |  kind.rawValue             << 21
    }
}

// MARK: - CustomStringConvertible

extension Move: CustomStringConvertible {
    public var description: String { uciString }
}
