//
//  ChessEngineController.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-30.
//

import Foundation

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
            DispatchQueue.main.async {
                self.identifyEngine()
                self.reportOptions()
                self.sendOk()
            }
        case "ucinewgame":
            DispatchQueue.main.async {
                self.waitForReady()
                self.board.initializeSearch()
                self.board.initializeNewBoard()
                self.engine = self.board.searchAgent
            }
        case "isready":
            DispatchQueue.main.async {
                self.waitForReady()
                respond("readyok")
            }
        case "go":
            // run go command asynchronously on the same queue that synchronous commands use
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
            DispatchQueue.main.async {
                self.handleStopCommand()
            }
        case "ponder":
            DispatchQueue.main.async {
                self.logger.log("queued ponder", level: Info)
                self.waitForReady()
                self.startPondering()
            }
        case "setoption":
            DispatchQueue.main.async {
                self.handleSetOption(Array(parts.dropFirst()))
            }
        
        // non-standard commands
        case "show":
            DispatchQueue.main.async {
                self.waitForReady()
                self.handleShowCommand(Array(parts.dropFirst()))
            }
        case "move":
            DispatchQueue.main.async {
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
        if let userInfo = Bundle.main.infoDictionary {
            guard
                let displayName = userInfo["CFBundleDisplayName"] as? String,
                let version = userInfo["CFBundleShortVersionString"] as? String,
                let author = userInfo["NSHumanReadableCopyright"] as? String
            else {
                return
            }
            respond("id name \(displayName) \(version)")
            respond("id author \(author)")
            respond("info string session id \(logger.sessionId!)")
        }
    }
    
    private func reportOptions() {
        respond("option name Hash type spin default 1 min 1 max 128")
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
        if uciParams["movetime"] == nil && uciParams["infinite"] == nil {
            let isWhite = board.activePlayer == board.whitePlayer
            let remaining = (uciParams[isWhite ? "wtime" : "btime"] as? Int) ?? 0
            let increment = (uciParams[isWhite ? "winc" : "binc"] as? Int) ?? 0
            if remaining > 0 {
                // Simple time allocation: use 1/30 of remaining time plus the increment,
                // with a floor of 100ms so we always make at least a minimal search.
                let movetime = max(100, remaining / 30 + increment)
                uciParams["movetime"] = movetime
                logger.log("time management: \(isWhite ? "white" : "black") remaining=\(remaining)ms inc=\(increment)ms → movetime=\(movetime)ms", level: Info)
            }
        }
        self.engine.performSearch(withUCIParams: uciParams)
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
        // Handle engine configuration
        respond("info string Option set: \(args.joined(separator: " "))")
    }
}
