//
//  main.swift
//  ChessEngine
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation

var board = ChessBoard()
board.initializeSearch()
board.initializeNewBoard()

func main() async throws {
  let args = CommandLine.arguments
  print(args)

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
  while true {
    print("> ", terminator: "")
    guard let line = readLine() else { break }
    await run(line)
  }
}

func run(_ source: String) async {
  let tokens = source.split(separator: " ")
  if let token = tokens.first {
    switch token {
    case "show":
      await print(board)
      break
    case "go":
      if let move = await board.searchAgent.findMove() {
        print(move)
        await board.nextMove(move)
      }
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
