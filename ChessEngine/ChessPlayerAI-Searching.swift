//
//  ChessPlayerAI-Searching.swift
//  Chess
//
//  Created by Steve Wart on 2025-07-30.
//

extension ChessPlayerAI {

    public enum ChessSearchStatus {
        case inProgress
        case completed
        case stopped
    }
    
    public enum AlphaBetaValues : Int32 {
        case AlphaBetaGiveUp = -29990
        case AlphaBetaIllegal = -31000
        case AlphaBetaMaxVal = 30000
        case AlphaBetaMinVal = -30000
    }
    
    public func performSearch(uciParams: [String: Any],
               updateCallback: @escaping ([String: Any]) -> Void,
                             completion: @escaping (String, [String: Any], ChessSearchStatus, Error?) -> Void)
    {
        // Extract UCI parameters
        let uci_depth = uciParams["depth"] as? Int32 ?? -1
        let uci_nodes = uciParams["nodes"] as? Int32 ?? -1
        let time_limit_ms = uciParams["movetime"] as? Double ?? -1.0 // ms
        if (uci_depth > 0) {
            depth_limit = uci_depth
        }
        if (uci_nodes > 0) {
            node_limit = uci_nodes
        }
        if (time_limit_ms > 0) {
            time_limit = (time_limit_ms / 1000.0)
        }
        let infinite = uciParams["infinite"] as? Bool ?? false
        
        if (transTable == nil) {
            initializeTranspositionTable()
        }
        setActivePlayer(board.activePlayer)
        myMove = ChessMove.null()
        
        let workItem = DispatchWorkItem { [self] in
            var status = ChessSearchStatus.inProgress
            var score = board.activePlayer.evaluate()
            var depth = 1
            var bestMove = ""
            var info: [String: Any] = [:]
            
            ply = 0
            historyTable.clear()
            transTable.clear()
            
            startTime = Date().timeIntervalSince1970
            nodesVisited = 0
            previousNodeCount = 0
            ttHits = 0
            alphaBetaCuts = 0
            initializeBestVariation()
            initializeActiveVariation()

            if board.hasUserAgent {
                NotificationCenter.default.postNotification(onMainThreadName:"StartedThinking")
            }

            // Search loop
            while status == .inProgress {
                
                let theMove = negaScout(board, depth: Int32(depth),
                                              alpha: AlphaBetaValues.AlphaBetaMinVal.rawValue,
                                              beta: AlphaBetaValues.AlphaBetaMaxVal.rawValue)
                
                let now = Date().timeIntervalSince1970
                let time_spent = now - startTime
                let currentNPS = Double(nodesVisited) / time_spent
                let pvMoves = pvMoves()
                
                // Prepare UCI info
                info["depth"] = depth
                info["score"] = ["cp": score] // centipawns
                info["nodes"] = nodesVisited
                info["time"] = (Int32)(time_spent * 1000.0)   /* elapsed time in ms */
                info["nps"] = currentNPS                      /* nodes per second */
                info["pv"] = pvMoves                          /* principal variation moves */
                
                // Send update
                DispatchQueue.main.async {
                    updateCallback(info)
                }
                
                if (theMove == nil) {
                    info["stop_reason"] = "no move found"
                }
                
                score = theMove!.value
                myMove = theMove
                assignBestVariation()
    
                depth += 1

                let stop_nodes = (node_limit > 0) && (nodesVisited > node_limit)
                let stop_depth = (depth_limit > 0) && (depth > depth_limit)
                let stop_time = ((time_limit > 0) && (time_spent > time_limit))

                if (stop_time) {
                    info["stop_reason"] = "time limit exceeded"
                }
                else if (stop_depth) {
                    info["stop_reason"] = "depth limit exceeded"
                }
                else if (stop_nodes) {
                    info["stop_reason"] = "node limit exceeded"
                }

                // Check termination conditions
                if stop_depth || stop_nodes || (!infinite && stop_time) || (theMove == nil) {
                    status = .completed
                    bestMove = (theMove != nil) ? theMove!.moveString() : "no move found"
                    if board.hasUserAgent {
                        NotificationCenter.default.postNotification(onMainThreadName:"StoppedThinking")
                    }
                }
                
                // Check cancellation
                if !isThinking() {
                    status = .stopped
                }
            }
            
            print("done")
            
            // Final completion
            DispatchQueue.main.async { [self] in
                completion(bestMove, info, status, nil)
                stopThinking()
                NotificationCenter.default.postNotification(onMainThreadName:"StoppedThinking", object:nil)
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
}
