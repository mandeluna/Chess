//
//  GameRecord.swift
//  Shambolic
//

import Foundation
import ChessEngine
import SQLite3

struct GameRecord: Identifiable {
    let id: Int64
    let startedAt: Date
    let updatedAt: Date
    var pgn: String
    var uciMoves: String        // space-separated: "e2e4 e7e5 g1f3"
    var startFEN: String?       // nil = standard starting position
    var finalFEN: String        // current/last board position
    var humanColor: PieceColor
    var outcome: Outcome?       // nil = in progress
    var finalCP: Int?
    var isCurrent: Bool

    enum Outcome: String {
        case white, black, draw

        var displayString: String {
            switch self {
            case .white: return "1-0"
            case .black: return "0-1"
            case .draw:  return "½-½"
            }
        }

        var label: String {
            switch self {
            case .white: return "White wins"
            case .black: return "Black wins"
            case .draw:  return "Draw"
            }
        }
    }

    /// Initialise from an open SQLite3 statement row.
    /// Column order must match GameStore.selectSQL.
    init?(stmt: OpaquePointer) {
        let iso = ISO8601DateFormatter()

        id          = sqlite3_column_int64(stmt, 0)

        let startStr  = String(cString: sqlite3_column_text(stmt, 1))
        let updateStr = String(cString: sqlite3_column_text(stmt, 2))
        startedAt   = iso.date(from: startStr)  ?? Date()
        updatedAt   = iso.date(from: updateStr) ?? Date()

        pgn         = String(cString: sqlite3_column_text(stmt, 3))
        uciMoves    = String(cString: sqlite3_column_text(stmt, 4))
        startFEN    = sqlite3_column_type(stmt, 5) != SQLITE_NULL
                        ? String(cString: sqlite3_column_text(stmt, 5)) : nil
        finalFEN    = String(cString: sqlite3_column_text(stmt, 6))
        humanColor  = String(cString: sqlite3_column_text(stmt, 7)) == "black" ? .black : .white
        outcome     = sqlite3_column_type(stmt, 8) != SQLITE_NULL
                        ? Outcome(rawValue: String(cString: sqlite3_column_text(stmt, 8))) : nil
        finalCP     = sqlite3_column_type(stmt, 9) != SQLITE_NULL
                        ? Int(sqlite3_column_int(stmt, 9)) : nil
        isCurrent   = sqlite3_column_int(stmt, 10) != 0
    }
}
