//
//  ChessEngineController.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-30.
//

import Foundation

class ChessEngineController {
    var board = ChessBoard()
    var engine: ChessPlayerAI

    private var currentSearchTask: DispatchWorkItem?
    private var isPondering = false
    
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
            identifyEngine()
            reportOptions()
            sendOk()
            logDebug("responded to uci")
        case "ucinewgame":
            board.initializeNewBoard()
        case "isready":
            Thread.sleep(forTimeInterval: 100.0 / 1000.0)
            print("readyok")
            logDebug("responded to isready")
        case "go":
            handleGoCommand(Array(parts.dropFirst()))
        case "position":
            handlePositionCommand(Array(parts.dropFirst()))
        case "debug":
            handleDebugCommand(Array(parts.dropFirst()))
        case "stop":
            handleStopCommand()
            logDebug("stopped search")
        case "ponder":
            startPondering()
        case "quit":
            stopSearch()
            logDebug("exiting")
            // don't exit until all buffers have been flushed
            fflush(__stdoutp)
            exit(0)
        case "setoption":
            handleSetOption(Array(parts.dropFirst()))
        
        // non-standard commands
        case "show":
            print(board.description()!)
        case "move":
            if (parts.count > 1) {
                handleMoveCommand(parts[1])
            }

        default:
            break
        }
    }
    
    private func handleMoveCommand(_ shortSAN: String) {
        board.applyMove(san: shortSAN)
    }
    
    private func handlePositionCommand(_ tokens: [String]) {
        NSLog("stopping search: \(tokens)")
        // Cancel any existing search
        stopSearch()

        NSLog("initializing board: \(tokens)")
        if let fenIndex = tokens.firstIndex(of: "fen") {

            let ranks = if tokens.count > 1 { String(tokens[fenIndex + 1]) } else { "" }
            let color = if tokens.count > 2 { String(tokens[fenIndex + 2]) } else { nil as String? }
            let castling = if tokens.count > 3 { String(tokens[fenIndex + 3]) } else { nil as String? }
            let enpassant = if tokens.count > 4 { String(tokens[fenIndex + 4]) } else { nil as String? }
            let halfmoves = if tokens.count > 5 { Int32(tokens[fenIndex + 5]) } else { nil as Int32? }
            let fullmoves = if tokens.count > 6 { Int32(tokens[fenIndex + 6]) } else { nil as Int32? }

            board.initializeFromFEN(ranks: ranks, color: color, castling: castling, enpassant: enpassant, halfmoves: halfmoves, fullmoves: fullmoves)
        }
        else if let _ = tokens.firstIndex(of: "startpos") {
            board.initializeNewBoard()
            let tokensString = tokens.joined(separator: " ")
            logDebug("responded to position startpos \(tokensString)")
        }
        if let moveIndex = tokens.firstIndex(of: "moves") {
            for i in moveIndex + 1 ..< tokens.count {
                board.applyMove(san: tokens[i])
            }
        }
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
            print("id name \(displayName) \(version)")
            print("id author \(author)")
            fflush(stdout)
        }
    }
    
    private func reportOptions() {
        print("option name Hash type spin default 1 min 1 max 128")
        fflush(stdout)
    }
    
    private func sendOk() {
        print("uciok")
        fflush(stdout)
    }

    private func handleDebugCommand(_ args: [String]) {
        if (args.count > 0) {
            engine.debug = args[0].lowercased() == "on"
        }
    }

    private func handleGoCommand(_ args: [String]) {
        // Cancel any existing search
        stopSearch()

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
                print("info string Unknown go parameter: \(args[i])")
            }
            i += 1
        }
        
        let searchTask = DispatchWorkItem {
            self.engine.performSearch(withUCIParams: uciParams)
        }
        
        currentSearchTask = searchTask
        Thread.sleep(forTimeInterval: 1.0)
        DispatchQueue.global(qos: .userInitiated).async(execute: searchTask)
    }
    
    private func stopSearch() {
        currentSearchTask?.cancel()
        engine.stopThinking()
        isPondering = false
    }
    
    private func handleStopCommand() {
        stopSearch()
        let bestMove = engine.myMove ?? ChessMove.null()
        let info = [
            "bestmove" : bestMove!.description()
        ]
        engine.printCompletionInfo(info as [AnyHashable : Any])
    }
    
    private func startPondering() {
        isPondering = true
        handleGoCommand(["infinite"])
        print("info string Pondering started")
    }
    
    private func handleSetOption(_ args: [String]) {
        // Handle engine configuration
        print("info string Option set: \(args.joined(separator: " "))")
    }
}
