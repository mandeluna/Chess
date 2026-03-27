//
//  GameStore.swift
//  Shambolic
//
//  Thin SQLite3 wrapper — no ORM, one table.
//  Add libsqlite3.tbd to Link Binary with Libraries if the linker complains.
//

import Foundation
import SQLite3

// SQLITE_TRANSIENT tells SQLite to copy the string immediately;
// needed for Swift Strings whose storage may move after the call.
private let SQLITE_TRANSIENT = unsafeBitCast(-1 as Int, to: sqlite3_destructor_type.self)

class GameStore {

    private var db: OpaquePointer?

    // Column order used by every SELECT — must match GameRecord.init(stmt:).
    static let selectSQL = """
        SELECT id, started_at, updated_at, pgn, uci_moves, start_fen, final_fen,
               human_color, outcome, final_cp, is_current
        FROM games
        """

    init() {
        let path = Self.dbPath()
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            print("GameStore: cannot open \(path)")
            return
        }
        exec("PRAGMA journal_mode=WAL")
        createTable()
    }

    deinit { sqlite3_close(db) }

    // MARK: - Schema

    private static func dbPath() -> String {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("games.sqlite").path
    }

    private func createTable() {
        exec("""
            CREATE TABLE IF NOT EXISTS games (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                started_at   TEXT    NOT NULL,
                updated_at   TEXT    NOT NULL,
                pgn          TEXT    NOT NULL DEFAULT '',
                uci_moves    TEXT    NOT NULL DEFAULT '',
                start_fen    TEXT,
                final_fen    TEXT    NOT NULL DEFAULT '',
                human_color  TEXT    NOT NULL DEFAULT 'white',
                outcome      TEXT,
                final_cp     INTEGER,
                is_current   INTEGER NOT NULL DEFAULT 0
            )
            """)
    }

    // MARK: - Public API

    /// Insert a new game row, mark it current, clear the flag on all others.
    /// Returns the new row id, or -1 on failure.
    @discardableResult
    func createGame(humanColor: String, startFEN: String?) -> Int64 {
        exec("UPDATE games SET is_current = 0")
        let now = iso()
        let initialFEN = startFEN ?? "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let sql = """
            INSERT INTO games
                (started_at, updated_at, pgn, uci_moves, start_fen, final_fen, human_color, is_current)
            VALUES (?, ?, '', '', ?, ?, ?, 1)
            """
        return withStatement(sql) { stmt in
            bind(stmt, 1, now)
            bind(stmt, 2, now)
            if let fen = startFEN { bind(stmt, 3, fen) } else { sqlite3_bind_null(stmt, 3) }
            bind(stmt, 4, initialFEN)
            bind(stmt, 5, humanColor)
            sqlite3_step(stmt)
            return sqlite3_last_insert_rowid(db)
        } ?? -1
    }

    /// Overwrite the live fields of the current game after each move.
    func updateCurrent(id: Int64, pgn: String, uciMoves: String, finalFEN: String, cp: Int?) {
        let sql = """
            UPDATE games
            SET updated_at=?, pgn=?, uci_moves=?, final_fen=?, final_cp=?
            WHERE id=?
            """
        withStatement(sql) { stmt in
            bind(stmt, 1, iso())
            bind(stmt, 2, pgn)
            bind(stmt, 3, uciMoves)
            bind(stmt, 4, finalFEN)
            if let cp { sqlite3_bind_int(stmt, 5, Int32(cp)) } else { sqlite3_bind_null(stmt, 5) }
            sqlite3_bind_int64(stmt, 6, id)
            sqlite3_step(stmt)
        }
    }

    /// Stamp the outcome when a game ends.
    func completeGame(id: Int64, outcome: String, finalCP: Int?) {
        let sql = "UPDATE games SET updated_at=?, outcome=?, final_cp=? WHERE id=?"
        withStatement(sql) { stmt in
            bind(stmt, 1, iso())
            bind(stmt, 2, outcome)
            if let cp = finalCP { sqlite3_bind_int(stmt, 3, Int32(cp)) } else { sqlite3_bind_null(stmt, 3) }
            sqlite3_bind_int64(stmt, 4, id)
            sqlite3_step(stmt)
        }
    }

    /// Make an existing game current; clears the flag on all others.
    func setCurrentGame(id: Int64) {
        exec("UPDATE games SET is_current = 0")
        exec("UPDATE games SET is_current = 1 WHERE id = \(id)")
    }

    /// All games, current first then most-recently-updated.
    func fetchAll() -> [GameRecord] {
        let sql = Self.selectSQL + " ORDER BY is_current DESC, updated_at DESC"
        return query(sql)
    }

    /// The game flagged is_current = 1, or nil if none.
    func fetchCurrent() -> GameRecord? {
        query(Self.selectSQL + " WHERE is_current = 1 LIMIT 1").first
    }

    // MARK: - Helpers

    @discardableResult
    private func exec(_ sql: String) -> Bool {
        var err: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            if let e = err { print("GameStore: \(String(cString: e))") }
            return false
        }
        return true
    }

    @discardableResult
    private func withStatement<T>(_ sql: String, _ body: (OpaquePointer) -> T) -> T? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return nil }
        defer { sqlite3_finalize(stmt) }
        return body(stmt)
    }

    private func query(_ sql: String) -> [GameRecord] {
        withStatement(sql) { stmt in
            var rows: [GameRecord] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let r = GameRecord(stmt: stmt) { rows.append(r) }
            }
            return rows
        } ?? []
    }

    private func bind(_ stmt: OpaquePointer, _ idx: Int32, _ value: String) {
        sqlite3_bind_text(stmt, idx, value, -1, SQLITE_TRANSIENT)
    }

    private func iso() -> String { ISO8601DateFormatter().string(from: Date()) }
}
