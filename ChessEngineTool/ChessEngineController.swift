//
//  ChessEngineController.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-30.
//

import Foundation
import ChessEngine

func respond(_ message: String) {
    // Always include newline and flush
    print(message)
    fflush(stdout)
}

class ChessEngineController {
    var board = ChessBoard()
    var engine: ChessPlayerAI
    var isPondering = false
    let logger = Logger.default()!

    private let searchQueue = DispatchQueue(label: "search_q", qos: .userInitiated)
    
    init() {
        board.initializeSearch()
        board.initializeNewBoard()
        engine = board.searchAgent
    }

    public func processCommand(_ command: String) {
        let parts = command.components(separatedBy: .whitespaces)
        guard !parts.isEmpty else { return }
        
        switch parts[0].lowercased() {
        case "uci":
            // Respond immediately — uciok must arrive before any other output.
            identifyEngine()
            reportOptions()
            sendOk()
        case "ucinewgame":
            // Run on searchQueue so it is serialized with position/go and cannot
            // race with board.move(uci:) calls that touch the generator.
            searchQueue.async {
                self.waitForReady()
                self.board.initializeSearch()
                self.board.initializeNewBoard()
                self.engine = self.board.searchAgent
            }
        case "isready":
            searchQueue.async {
                self.waitForReady()
                respond("readyok")
            }
        case "go":
            let args = Array(parts.dropFirst())
            searchQueue.async {
                if self.engine.status == .inProgress {
                    self.stopSearch()
                }
                self.logger.log("queued go \(args.joined(separator: " "))", level: Info)
                self.waitForReady()
                self.handleGoCommand(args)
            }
        case "position":
            searchQueue.async {
                self.waitForReady()
                self.handlePositionCommand(Array(parts.dropFirst()))
            }
        case "debug":
            handleDebugCommand(Array(parts.dropFirst()))
        case "stop":
            // Set the cancel flag synchronously so the search sees it immediately,
            // regardless of which thread or queue this command arrives on.
            handleStopCommand()
        case "setoption":
            handleSetOption(Array(parts.dropFirst()))
        case "ponder":
            // Pondering runs a blocking search — must be on searchQueue, not main.
            searchQueue.async {
                self.logger.log("queued ponder", level: Info)
                self.waitForReady()
                self.startPondering()
            }

        // non-standard commands
        case "show":
            searchQueue.async {
                self.waitForReady()
                self.handleShowCommand(Array(parts.dropFirst()))
            }
        case "move":
            searchQueue.async {
                self.waitForReady()
                if (parts.count > 1) {
                    self.handleMoveCommand(parts[1])
                }
            }

        default:
            break
        }
    }
    
    private func handleMoveCommand(_ moveText: String) {
        let move = board.move(uci: moveText)
        board.nextMove(move)
    }
    
    private func handleShowCommand(_ tokens: [String]) {
        if tokens.firstIndex(of: "fen") != nil {
            respond(self.board.generateFEN())
        }
        else {
            respond(self.board.description()!)
        }
    }
    
    private func handlePositionCommand(_ tokens: [String]) {
        // don't muck up the board if a search is in progress
        logger.logMessage("Waiting for engine ready: position \(tokens.joined(separator:" "))")
        self.waitForReady()
        logger.logMessage("Engine is ready: position \(tokens.joined(separator:" "))")

        if let fenIndex = tokens.firstIndex(of: "fen") {

            let ranks = if tokens.count > 1 { String(tokens[fenIndex + 1]) } else { "" }
            let color = if tokens.count > 2 { String(tokens[fenIndex + 2]) } else { nil as String? }
            let castling = if tokens.count > 3 { String(tokens[fenIndex + 3]) } else { nil as String? }
            let enpassant = if tokens.count > 4 { String(tokens[fenIndex + 4]) } else { nil as String? }
            let halfmoves = if tokens.count > 5 { Int32(tokens[fenIndex + 5]) } else { nil as Int32? }
            let fullmoves = if tokens.count > 6 { Int32(tokens[fenIndex + 6]) } else { nil as Int32? }

            self.board.initializeSearch()
            self.board.initializeFromFEN(ranks: ranks, color: color, castling: castling, enpassant: enpassant, halfmoves: halfmoves, fullmoves: fullmoves)
        }
        else if let _ = tokens.firstIndex(of: "startpos") {
            self.board.initializeNewBoard()
        }
        if let moveIndex = tokens.firstIndex(of: "moves") {
            for i in moveIndex + 1 ..< tokens.count {
                let move = self.board.move(uci: tokens[i])
                board.nextMove(move)
            }
        }
        logger.logMessage("position \(tokens.joined(separator:" "))")
        logger.logMessage(self.board.description())
    }

    private func identifyEngine() {
        let name = "\(ChessEngineInfo.displayName) \(ChessEngineInfo.version) build \(ChessEngineInfo.buildNumber)"
        respond("id name \(name)")
        respond("id author \(ChessEngineInfo.author)")
        respond("info string session id \(logger.sessionId!)")

        logger.logMessage("name \(name)")
    }
    
    private func reportOptions() {
        respond("option name Hash type spin default 128 min 1 max 512")
    }
    
    private func sendOk() {
        respond("uciok")
    }

    private func handleDebugCommand(_ args: [String]) {
        if (args.count > 0) {
            logger.level = if args[0].lowercased() == "on" { Verbose } else { None }
        }
    }

    private func handleGoCommand(_ args: [String]) {
        var uciParams: [String: Any] = [:]
        var i = 0
        while i < args.count {
            switch args[i].lowercased() {
            case "infinite":
                uciParams["infinite"] = true
            case "depth":
                if i+1 < args.count, let depth = Int(args[i+1]) {
                    uciParams["depth"] = depth
                    i += 1
                }
            case "nodes":
                if i+1 < args.count, let nodes = Int(args[i+1]) {
                    uciParams["nodes"] = nodes
                    i += 1
                }
            case "movetime":
                if i+1 < args.count, let movetime = Int(args[i+1]) {
                    uciParams["movetime"] = movetime
                    i += 1
                }
            case "wtime", "btime", "winc", "binc":
                if i+1 < args.count, let time = Int(args[i+1]) {
                    uciParams[args[i]] = time
                    i += 1
                }
            case "movestogo":
                if i+1 < args.count, let n = Int(args[i+1]) {
                    uciParams["movestogo"] = n
                    i += 1
                }
            case "ponder":
                uciParams["ponder"] = true
            default:
                respond("info string Unknown go parameter: \(args[i])")
                logger.logMessage("handleGoCommand: Unknown go parameter: \(args[i])")
            }
            i += 1
        }
        // Convert wtime/btime/winc/binc to a movetime if not already specified.
        // The engine plays whichever color is active on the board.
        if uciParams["movetime"] == nil && uciParams["depth"] == nil && uciParams["infinite"] == nil {
            let isWhite = board.activePlayer == board.whitePlayer
            let remaining = (uciParams[isWhite ? "wtime" : "btime"] as? Int) ?? 0
            let increment = (uciParams[isWhite ? "winc" : "binc"] as? Int) ?? 0
            if remaining > 0 {
                let movetime = allocateTime(remaining: remaining, increment: increment,
                                            movestogo: uciParams["movestogo"] as? Int)
                uciParams["movetime"] = movetime
                let movestogoStr = (uciParams["movestogo"] as? Int).map { "/\($0)" } ?? ""
                logger.log("time management: \(isWhite ? "white" : "black") remaining=\(remaining)ms inc=\(increment)ms movestogo\(movestogoStr) → movetime=\(movetime)ms", level: Info)
            }
        }
        self.engine.performSearch(withUCIParams: uciParams)
    }
    
    /// Calculate how many milliseconds to allocate for the current move.
    ///
    /// When `movestogo` is provided (e.g. CCRL 40/15), we divide the remaining
    /// time evenly across those moves plus a one-move buffer, then add the
    /// increment.  When it is absent (sudden-death or Fischer clock) we estimate
    /// ~30 moves remain.  A 50 ms overhead reserve prevents flagging on lag.
    private func allocateTime(remaining: Int, increment: Int, movestogo: Int?) -> Int {
        let overhead = 50
        let safeRemaining = max(0, remaining - overhead)
        let divisor = (movestogo ?? 0) > 0 ? movestogo! + 1 : 30
        let allocated = safeRemaining / divisor + increment
        // Never spend more than half the remaining time on a single move (safety cap).
        let capped = min(allocated, safeRemaining / 2)
        return max(100, capped)
    }

    private func stopSearch() {
        engine.cancelSearch()
        isPondering = false
    }

    public func waitForReady() {
        while engine.isSearching {
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
    
    private func handleStopCommand() {
        if engine.status == .inProgress {
            stopSearch()
            waitForReady()
        }
    }
    
    private func startPondering() {
        isPondering = true
        handleGoCommand(["infinite"])
        respond("info string Pondering started")
    }
    
    private func handleSetOption(_ args: [String]) {
        // Expected format: name <Name> value <Value>
        guard let nameIdx = args.firstIndex(of: "name"),
              let valueIdx = args.firstIndex(of: "value"),
              valueIdx > nameIdx else { return }
        let name = args[(nameIdx + 1) ..< valueIdx].joined(separator: " ")
        let value = args[(valueIdx + 1)...].joined(separator: " ")
        switch name.lowercased() {
        case "hash":
            if let mb = Int32(value) {
                engine.setHashSizeMB(mb)
                respond("info string Hash set to \(mb) MB")
            }
        default:
            respond("info string Unknown option: \(name)")
        }
    }
}
