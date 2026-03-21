//
//  MoveGenerator.swift
//  ChessEngine
//
//  Pure-Swift move generator.  Takes two piece arrays (mine / opponent's) plus
//  position metadata and returns a ContiguousArray<Move> — no pool, no recycling,
//  no reference counting on individual moves.
//
//  Square encoding (matches ObjC engine):
//    square = rank * 8 + file    rank 0 = rank-1 (white back rank)
//    file   = square & 7         0 = a-file, 7 = h-file
//    rank   = square >> 3        0 = rank-1, 7 = rank-8

// MARK: - Piece / castling constants (must match ObjC ChessMoveGenerator.h)

private let kPawn   = 1, kKnight = 2, kBishop = 3
private let kRook   = 4, kQueen  = 5, kKing   = 6

// Castling status bits.  Castling is ENABLED when the relevant bits are all 0.
// Once kCastlingDone or a disable flag is set it is permanently disabled.
private let kCastlingDone             = 1   // 0b001 — castling has occurred / can't happen
private let kCastlingDisableKingSide  = 2   // 0b010
private let kCastlingDisableQueenSide = 4   // 0b100
private let kCastlingEnableKingSide   = kCastlingDone | kCastlingDisableKingSide   // 3
private let kCastlingEnableQueenSide  = kCastlingDone | kCastlingDisableQueenSide  // 5

// MARK: - Result type

/// Output of a single move-generation call.
struct MoveList {
    /// Pseudo-legal moves for the side to move (captures only when `quiescence` is true).
    /// Always empty when `kingAttack` is set.
    var moves: ContiguousArray<Move>
    /// Non-nil when the opponent's king can be captured: the previous half-move was illegal.
    var kingAttack: Move?

    init() {
        moves = ContiguousArray()
        moves.reserveCapacity(48)
        kingAttack = nil
    }
}

// MARK: - MoveGenerator

/// Singleton move generator.  All mutable state is local to each `generate` call,
/// so this is thread-safe after `shared` is first accessed.
final class MoveGenerator: @unchecked Sendable {

    static let shared = MoveGenerator()
    private init() {}

    // MARK: Pre-computed tables (lazily initialised, thread-safe via Swift runtime)

    /// rookRays[sq]: up to 4 rays (E, N, W, S), each listing squares in order of distance.
    private static let rookRays:   [[[Int]]] = buildRookRays()
    /// bishopRays[sq]: up to 4 diagonal rays (NE, NW, SW, SE).
    private static let bishopRays: [[[Int]]] = buildBishopRays()
    /// kingTargets[sq]: up to 8 adjacent squares.
    private static let kingTargets:   [[Int]] = buildKingTargets()
    /// knightTargets[sq]: up to 8 knight-reachable squares.
    private static let knightTargets: [[Int]] = buildKnightTargets()

    // MARK: - Public entry point

    /// Generate pseudo-legal moves for the side whose pieces are in `myPieces`.
    ///
    /// - Parameters:
    ///   - myPieces:        64-byte piece array for the moving side (0 = empty, 1–6 = piece type).
    ///   - itsPieces:       64-byte piece array for the opponent.
    ///   - castlingStatus:  Castling flags from `ChessPlayer.castlingStatus`.
    ///   - enpassantSquare: Target square for en-passant captures (0 = none).
    ///   - isWhite:         True when the moving side is white.
    ///   - quiescence:      When true, generate captures only (pawn pushes omitted).
    func generate(
        myPieces my: UnsafePointer<UInt8>,
        itsPieces its: UnsafePointer<UInt8>,
        castlingStatus: Int,
        enpassantSquare: Int,
        isWhite: Bool,
        quiescence: Bool
    ) -> MoveList {
        var result = MoveList()

        for sq in 0..<64 {
            let piece = Int(my[sq])
            guard piece != 0 else { continue }

            switch piece {
            case kPawn:
                appendPawnMoves(from: sq, my: my, its: its,
                                enpassant: enpassantSquare, isWhite: isWhite,
                                quiescence: quiescence, into: &result)
            case kKnight:
                appendKnightMoves(from: sq, piece: piece, my: my, its: its,
                                   quiescence: quiescence, into: &result)
            case kBishop:
                appendSlidingMoves(from: sq, piece: piece,
                                    rays: Self.bishopRays[sq],
                                    my: my, its: its,
                                    quiescence: quiescence, into: &result)
            case kRook:
                appendSlidingMoves(from: sq, piece: piece,
                                    rays: Self.rookRays[sq],
                                    my: my, its: its,
                                    quiescence: quiescence, into: &result)
            case kQueen:
                appendSlidingMoves(from: sq, piece: piece,
                                    rays: Self.bishopRays[sq],
                                    my: my, its: its,
                                    quiescence: quiescence, into: &result)
                if result.kingAttack == nil {
                    appendSlidingMoves(from: sq, piece: piece,
                                        rays: Self.rookRays[sq],
                                        my: my, its: its,
                                        quiescence: quiescence, into: &result)
                }
            case kKing:
                appendKingMoves(from: sq, piece: piece,
                                 my: my, its: its,
                                 castlingStatus: castlingStatus,
                                 isWhite: isWhite, quiescence: quiescence,
                                 into: &result)
            default:
                break
            }

            if result.kingAttack != nil {
                result.moves.removeAll(keepingCapacity: false)
                return result
            }
        }

        return result
    }

    // MARK: - Piece-specific generators

    private func appendPawnMoves(
        from sq: Int,
        my: UnsafePointer<UInt8>,
        its: UnsafePointer<UInt8>,
        enpassant: Int,
        isWhite: Bool,
        quiescence: Bool,
        into result: inout MoveList
    ) {
        let file = sq & 7
        if isWhite {
            // Diagonal captures (always generated, even in quiescence)
            if file > 0 { whitePawnCapture(from: sq, to: sq + 7, its: its, into: &result) }
            if file < 7 { whitePawnCapture(from: sq, to: sq + 9, its: its, into: &result) }
            if result.kingAttack != nil { return }

            // En-passant captures
            if enpassant != 0 {
                if file > 0, sq + 7 == enpassant {
                    result.moves.append(.enPassant(piece: kPawn, from: sq, to: enpassant, captured: kPawn))
                }
                if file < 7, sq + 9 == enpassant {
                    result.moves.append(.enPassant(piece: kPawn, from: sq, to: enpassant, captured: kPawn))
                }
            }

            // Pushes (omitted in quiescence; promotions via push also omitted)
            guard !quiescence else { return }
            let push = sq + 8
            guard my[push] == 0, its[push] == 0 else { return }
            if push > 55 {
                appendPromotions(from: sq, to: push, captured: 0, into: &result)
                return
            }
            result.moves.append(.move(piece: kPawn, from: sq, to: push))
            // Double push from starting rank (squares 8–15)
            if sq < 16 {
                let dbl = sq + 16
                if my[dbl] == 0, its[dbl] == 0 {
                    result.moves.append(.doublePush(piece: kPawn, from: sq, to: dbl))
                }
            }
        } else {
            // Black pawn
            if file > 0 { blackPawnCapture(from: sq, to: sq - 9, its: its, into: &result) }
            if file < 7 { blackPawnCapture(from: sq, to: sq - 7, its: its, into: &result) }
            if result.kingAttack != nil { return }

            if enpassant != 0 {
                if file > 0, sq - 9 == enpassant {
                    result.moves.append(.enPassant(piece: kPawn, from: sq, to: enpassant, captured: kPawn))
                }
                if file < 7, sq - 7 == enpassant {
                    result.moves.append(.enPassant(piece: kPawn, from: sq, to: enpassant, captured: kPawn))
                }
            }

            guard !quiescence else { return }
            let push = sq - 8
            guard my[push] == 0, its[push] == 0 else { return }
            if push < 8 {
                appendPromotions(from: sq, to: push, captured: 0, into: &result)
                return
            }
            result.moves.append(.move(piece: kPawn, from: sq, to: push))
            // Double push from starting rank (squares 48–55)
            if sq >= 48 {
                let dbl = sq - 16
                if my[dbl] == 0, its[dbl] == 0 {
                    result.moves.append(.doublePush(piece: kPawn, from: sq, to: dbl))
                }
            }
        }
    }

    private func whitePawnCapture(from sq: Int, to dest: Int,
                                   its: UnsafePointer<UInt8>,
                                   into result: inout MoveList) {
        let cap = Int(its[dest])
        guard cap != 0 else { return }
        if cap == kKing {
            result.kingAttack = .move(piece: kPawn, from: sq, to: dest, captured: cap)
            return
        }
        if dest > 55 {
            appendPromotions(from: sq, to: dest, captured: cap, into: &result)
        } else {
            result.moves.append(.move(piece: kPawn, from: sq, to: dest, captured: cap))
        }
    }

    private func blackPawnCapture(from sq: Int, to dest: Int,
                                   its: UnsafePointer<UInt8>,
                                   into result: inout MoveList) {
        let cap = Int(its[dest])
        guard cap != 0 else { return }
        if cap == kKing {
            result.kingAttack = .move(piece: kPawn, from: sq, to: dest, captured: cap)
            return
        }
        if dest < 8 {
            appendPromotions(from: sq, to: dest, captured: cap, into: &result)
        } else {
            result.moves.append(.move(piece: kPawn, from: sq, to: dest, captured: cap))
        }
    }

    /// Append four promotion moves (knight, bishop, rook, queen) for a pawn reaching the back rank.
    private func appendPromotions(from sq: Int, to dest: Int, captured: Int,
                                   into result: inout MoveList) {
        result.moves.append(.promotion(piece: kPawn, from: sq, to: dest, promoteTo: kKnight, captured: captured))
        result.moves.append(.promotion(piece: kPawn, from: sq, to: dest, promoteTo: kBishop, captured: captured))
        result.moves.append(.promotion(piece: kPawn, from: sq, to: dest, promoteTo: kRook,   captured: captured))
        result.moves.append(.promotion(piece: kPawn, from: sq, to: dest, promoteTo: kQueen,  captured: captured))
    }

    private func appendKnightMoves(from sq: Int, piece: Int,
                                    my: UnsafePointer<UInt8>,
                                    its: UnsafePointer<UInt8>,
                                    quiescence: Bool,
                                    into result: inout MoveList) {
        for dest in Self.knightTargets[sq] {
            guard my[dest] == 0 else { continue }
            let cap = Int(its[dest])
            if quiescence, cap == 0 { continue }
            if cap == kKing {
                result.kingAttack = .move(piece: piece, from: sq, to: dest, captured: cap)
                return
            }
            result.moves.append(.move(piece: piece, from: sq, to: dest, captured: cap))
        }
    }

    /// Slide `piece` along each ray until blocked; append moves.
    private func appendSlidingMoves(from sq: Int, piece: Int, rays: [[Int]],
                                     my: UnsafePointer<UInt8>,
                                     its: UnsafePointer<UInt8>,
                                     quiescence: Bool,
                                     into result: inout MoveList) {
        for ray in rays {
            for dest in ray {
                if my[dest] != 0 { break }          // blocked by own piece
                let cap = Int(its[dest])
                if !quiescence || cap != 0 {
                    if cap == kKing {
                        result.kingAttack = .move(piece: piece, from: sq, to: dest, captured: cap)
                        return
                    }
                    result.moves.append(.move(piece: piece, from: sq, to: dest, captured: cap))
                }
                if cap != 0 { break }               // blocked after capture
            }
        }
    }

    private func appendKingMoves(from sq: Int, piece: Int,
                                  my: UnsafePointer<UInt8>,
                                  its: UnsafePointer<UInt8>,
                                  castlingStatus: Int,
                                  isWhite: Bool,
                                  quiescence: Bool,
                                  into result: inout MoveList) {
        for dest in Self.kingTargets[sq] {
            guard my[dest] == 0 else { continue }
            let cap = Int(its[dest])
            if quiescence, cap == 0 { continue }
            if cap == kKing {
                result.kingAttack = .move(piece: piece, from: sq, to: dest, captured: cap)
                return
            }
            result.moves.append(.move(piece: piece, from: sq, to: dest, captured: cap))
        }

        guard !quiescence else { return }

        // Castling — attacker is the opponent; `attackerIsWhite` flips relative to `isWhite`.
        if isWhite {
            if canCastleWhiteKingside(castlingStatus: castlingStatus, my: my, its: its) {
                result.moves.append(.castleKingside(piece: piece, from: sq, to: sq + 2))
            }
            if canCastleWhiteQueenside(castlingStatus: castlingStatus, my: my, its: its) {
                result.moves.append(.castleQueenside(piece: piece, from: sq, to: sq - 2))
            }
        } else {
            if canCastleBlackKingside(castlingStatus: castlingStatus, my: my, its: its) {
                result.moves.append(.castleKingside(piece: piece, from: sq, to: sq + 2))
            }
            if canCastleBlackQueenside(castlingStatus: castlingStatus, my: my, its: its) {
                result.moves.append(.castleQueenside(piece: piece, from: sq, to: sq - 2))
            }
        }
    }

    // MARK: - Castling legality

    // castlingStatus & kCastlingEnableXxx != 0  →  permanently disabled.

    private func canCastleWhiteKingside(castlingStatus: Int,
                                         my: UnsafePointer<UInt8>,
                                         its: UnsafePointer<UInt8>) -> Bool {
        guard castlingStatus & kCastlingEnableKingSide == 0 else { return false }
        // F1 = 5, G1 = 6 must be clear (H1 = 7 has the rook — stays put until castling)
        guard my[5] == 0, my[6] == 0, its[5] == 0, its[6] == 0 else { return false }
        // King travels E1(4) → G1(6); none of those squares may be attacked by black
        return !isSquareAttacked(4, attackerIsWhite: false, attacker: its, blocker: my)
            && !isSquareAttacked(5, attackerIsWhite: false, attacker: its, blocker: my)
            && !isSquareAttacked(6, attackerIsWhite: false, attacker: its, blocker: my)
    }

    private func canCastleWhiteQueenside(castlingStatus: Int,
                                          my: UnsafePointer<UInt8>,
                                          its: UnsafePointer<UInt8>) -> Bool {
        guard castlingStatus & kCastlingEnableQueenSide == 0 else { return false }
        // B1(1), C1(2), D1(3) must be clear — A1(0) has the rook
        guard my[1] == 0, my[2] == 0, my[3] == 0,
              its[1] == 0, its[2] == 0, its[3] == 0 else { return false }
        // King travels E1(4) → C1(2); D1(3) is also in the path
        return !isSquareAttacked(4, attackerIsWhite: false, attacker: its, blocker: my)
            && !isSquareAttacked(3, attackerIsWhite: false, attacker: its, blocker: my)
            && !isSquareAttacked(2, attackerIsWhite: false, attacker: its, blocker: my)
    }

    private func canCastleBlackKingside(castlingStatus: Int,
                                         my: UnsafePointer<UInt8>,
                                         its: UnsafePointer<UInt8>) -> Bool {
        guard castlingStatus & kCastlingEnableKingSide == 0 else { return false }
        // F8 = 61, G8 = 62 must be clear (H8 = 63 has the rook)
        guard my[61] == 0, my[62] == 0, its[61] == 0, its[62] == 0 else { return false }
        return !isSquareAttacked(60, attackerIsWhite: true, attacker: its, blocker: my)
            && !isSquareAttacked(61, attackerIsWhite: true, attacker: its, blocker: my)
            && !isSquareAttacked(62, attackerIsWhite: true, attacker: its, blocker: my)
    }

    private func canCastleBlackQueenside(castlingStatus: Int,
                                          my: UnsafePointer<UInt8>,
                                          its: UnsafePointer<UInt8>) -> Bool {
        guard castlingStatus & kCastlingEnableQueenSide == 0 else { return false }
        // B8(57), C8(58), D8(59) must be clear — A8(56) has the rook
        guard my[57] == 0, my[58] == 0, my[59] == 0,
              its[57] == 0, its[58] == 0, its[59] == 0 else { return false }
        return !isSquareAttacked(60, attackerIsWhite: true, attacker: its, blocker: my)
            && !isSquareAttacked(59, attackerIsWhite: true, attacker: its, blocker: my)
            && !isSquareAttacked(58, attackerIsWhite: true, attacker: its, blocker: my)
    }

    // MARK: - Attack detection

    /// Returns true if `sq` is attacked by any piece in `its`.
    ///
    /// `attackerIsWhite` determines pawn attack direction.
    /// `my` provides blocking pieces (own pieces block sliding-piece rays).
    private func isSquareAttacked(
        _ sq: Int,
        attackerIsWhite: Bool,
        attacker its: UnsafePointer<UInt8>,
        blocker my: UnsafePointer<UInt8>
    ) -> Bool {
        // Rook / queen (rank and file rays)
        for ray in Self.rookRays[sq] {
            for dest in ray {
                if my[dest] != 0 { break }
                if its[dest] != 0 {
                    let p = Int(its[dest])
                    if p == kRook || p == kQueen { return true }
                    break
                }
            }
        }
        // Bishop / queen (diagonal rays)
        for ray in Self.bishopRays[sq] {
            for dest in ray {
                if my[dest] != 0 { break }
                if its[dest] != 0 {
                    let p = Int(its[dest])
                    if p == kBishop || p == kQueen { return true }
                    break
                }
            }
        }
        // Knight
        for dest in Self.knightTargets[sq] {
            if Int(its[dest]) == kKnight { return true }
        }
        // King
        for dest in Self.kingTargets[sq] {
            if Int(its[dest]) == kKing { return true }
        }
        // Pawn
        // A pawn at P attacks P±7 and P±9 (direction depends on color).
        // Square sq is attacked by a pawn at P iff P is an adjacent-file square one rank away.
        let file = sq & 7
        let pawnAtk = UInt8(kPawn)
        if attackerIsWhite {
            // White pawn attacks upward (+7/+9); sq is attacked from below (sq-7 or sq-9)
            let p1 = sq - 7
            if p1 >= 0, abs((p1 & 7) - file) == 1, its[p1] == pawnAtk { return true }
            let p2 = sq - 9
            if p2 >= 0, abs((p2 & 7) - file) == 1, its[p2] == pawnAtk { return true }
        } else {
            // Black pawn attacks downward (-7/-9); sq is attacked from above (sq+7 or sq+9)
            let p1 = sq + 7
            if p1 < 64, abs((p1 & 7) - file) == 1, its[p1] == pawnAtk { return true }
            let p2 = sq + 9
            if p2 < 64, abs((p2 & 7) - file) == 1, its[p2] == pawnAtk { return true }
        }
        return false
    }

    // MARK: - Table builders

    private static func buildRookRays() -> [[[Int]]] {
        (0..<64).map { sq in
            let f = sq & 7, r = sq >> 3
            return [
                (f + 1 ..< 8).map { r * 8 + $0 },                       // E
                (r + 1 ..< 8).map { $0 * 8 + f },                       // N
                stride(from: f - 1, through: 0, by: -1).map { r * 8 + $0 }, // W
                stride(from: r - 1, through: 0, by: -1).map { $0 * 8 + f }, // S
            ]
        }
    }

    private static func buildBishopRays() -> [[[Int]]] {
        (0..<64).map { sq in
            let f = sq & 7, r = sq >> 3
            var ne: [Int] = [], nw: [Int] = [], sw: [Int] = [], se: [Int] = []
            for k in 1..<8 {
                if f + k < 8, r + k < 8 { ne.append((r + k) * 8 + (f + k)) }
                if f - k >= 0, r + k < 8 { nw.append((r + k) * 8 + (f - k)) }
                if f - k >= 0, r - k >= 0 { sw.append((r - k) * 8 + (f - k)) }
                if f + k < 8, r - k >= 0 { se.append((r - k) * 8 + (f + k)) }
            }
            return [ne, nw, sw, se]
        }
    }

    private static func buildKingTargets() -> [[Int]] {
        (0..<64).map { sq in
            let f = sq & 7, r = sq >> 3
            var t: [Int] = []
            for dr in -1...1 {
                for df in -1...1 {
                    guard dr != 0 || df != 0 else { continue }
                    let nr = r + dr, nf = f + df
                    if nr >= 0, nr < 8, nf >= 0, nf < 8 { t.append(nr * 8 + nf) }
                }
            }
            return t
        }
    }

    private static func buildKnightTargets() -> [[Int]] {
        let deltas = [(-2,-1),(-1,-2),(1,-2),(2,-1),(2,1),(1,2),(-1,2),(-2,1)]
        return (0..<64).map { sq in
            let f = sq & 7, r = sq >> 3
            return deltas.compactMap { (dr, df) in
                let nr = r + dr, nf = f + df
                guard nr >= 0, nr < 8, nf >= 0, nf < 8 else { return nil }
                return nr * 8 + nf
            }
        }
    }
}
