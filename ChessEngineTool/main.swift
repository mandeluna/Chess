//
//  main.swift
//  ChessEngine
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation
import LineNoise

var board = ChessBoard()
board.initializeSearch()
board.initializeNewBoard()

func main() async throws {

  let args = CommandLine.arguments

  if args.count > 2 {
    print("Usage: {} <script>")
    exit(64)
  }
  else if args.count == 2 {
    try await runFile(args[1])
  }
  else {
    try await runPrompt()
  }
}

func runFile(_ path: String) async throws {
  let string = try String(contentsOfFile: path, encoding:.utf8)
  await run(string)
}

func runPrompt() async throws {
  let ln = LineNoise()
  while true {
    do {
      let line = try ln.getLine(prompt:"")
      ln.addHistory(line)
      await run(line)
    }
    catch {
      print(error)
    }
  }
}

func run(_ source: String) async {
  let tokens = source.split(separator: " ")
  if let token = tokens.first {
    switch token {
    case "uci":
      print("id name Chamonix 2025.07.29")
      print("id author Steven Wart based on the work of Andreas Raab")
      print("option name Debug Log File type string default <empty>")
      print("option name Ponder type check default false")
      print("uciok")
      break
    case "isready":
      print("readyok")
      break
    case "show":
      await print(board)
      break
    case "go":
      print("info string NegaScout evaluation using Squeak6.0-22148-64bit enabled")
      print("info depth 1 seldepth 1 multipv 1 score cp 18 nodes 20 nps 4000 hashfull 0 tbhits 0 time 5 pv e2e4")
      print("info depth 2 seldepth 2 multipv 1 score cp 46 nodes 66 nps 11000 hashfull 0 tbhits 0 time 6 pv d2d4")
      print("info depth 3 seldepth 2 multipv 1 score cp 51 nodes 120 nps 20000 hashfull 0 tbhits 0 time 6 pv e2e4")
      print("info depth 4 seldepth 2 multipv 1 score cp 58 nodes 144 nps 18000 hashfull 0 tbhits 0 time 8 pv d2d4")
      print("info depth 5 seldepth 2 multipv 1 score cp 58 nodes 174 nps 15818 hashfull 0 tbhits 0 time 11 pv d2d4 a7a6")
      print("info depth 6 seldepth 7 multipv 1 score cp 34 nodes 1303 nps 81437 hashfull 0 tbhits 0 time 16 pv e2e4 c7c5 g1f3 b8c6 c2c3")
      print("info depth 7 seldepth 6 multipv 1 score cp 29 nodes 3126 nps 120230 hashfull 1 tbhits 0 time 26 pv d2d4 g8f6 e2e3 d7d5 c2c4 d5c4")
      print("info depth 8 seldepth 7 multipv 1 score cp 26 nodes 5791 nps 152394 hashfull 4 tbhits 0 time 38 pv g1f3 g8f6 d2d4 d7d5 e2e3")
      print("info depth 9 seldepth 9 multipv 1 score cp 31 nodes 8541 nps 174306 hashfull 5 tbhits 0 time 49 pv g1f3 c7c5 e2e4 e7e6 d2d4 c5d4 f3d4")
      print("info depth 10 seldepth 13 multipv 1 score cp 25 nodes 20978 nps 209780 hashfull 10 tbhits 0 time 100 pv e2e4 c7c5 g1f3 b8c6 f1c4 e7e6 e1g1 g8f6")
      print("info depth 11 seldepth 13 multipv 1 score cp 32 nodes 29040 nps 220000 hashfull 14 tbhits 0 time 132 pv e2e4 c7c5 c2c3 g8f6 e4e5 f6d5 d2d4")
      print("info depth 12 seldepth 14 multipv 1 score cp 38 nodes 41207 nps 242394 hashfull 18 tbhits 0 time 170 pv e2e4 e7e6 d2d4 d7d5 b1c3 d5e4 c3e4")
      break
  case "stop":
      print("info depth 13 seldepth 14 multipv 1 score cp 38 nodes 45531 nps 247451 hashfull 21 tbhits 0 time 184 pv e2e4 e7e6 d2d4 d7d5 b1c3 d5e4 c3e4")
      print("bestmove e2e4 ponder e7e6")
//      if let move = await board.searchAgent.findMove() {
//        let depth = board.searchAgent.depth
//        let score = board.searchAgent.score
//        let node_count = board.searchAgent.node_count
//        print("info depth \(depth) score \(score) nodes \(node_count")
//        await board.nextMove(move)
//      }
      break
    case "quit":
      exit(0)
      break
    case "position":
      handlePositionCommand(tokens)
      break
    default:
      // do not print anything for unrecognized commands
      break
    }
  }
}

// 00008,r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24,f2g3 e6e7 b2b1 b3c1 b1c1 h6c1,1978,77,95,8125,crushing hangingPiece long middlegame,https://lichess.org/787zsVup/black#48
// --> results in index out of range exception (castling king side during board search)
// TODO parse next player to move
// TODO implicitly make first move
// TODO unit tests to validate subsequent moves
// TODO parse moves in UCI format, display them in SAN (with unicode glyphs)
func handlePositionCommand(_ tokens: [Substring]) {
  if let fenIndex = tokens.firstIndex(of: "fen") {

    let ranks = String(tokens[fenIndex + 1])
    let color = String(tokens[fenIndex + 2])
    let castling = String(tokens[fenIndex + 3])
    let enpassant = String(tokens[fenIndex + 4])
    let halfmoves = Int32(tokens[fenIndex + 5])
    let fullmoves = Int32(tokens[fenIndex + 6])

    board.initializeFromFEN(ranks: ranks, color: color, castling: castling, enpassant: enpassant, halfmoves: halfmoves, fullmoves: fullmoves)
  }
  else if let startposIndex = tokens.firstIndex(of: "startpos") {
    print("> position startpos command")
  }
  else {
    print("> Invalid position command")
  }
}

try await main()
