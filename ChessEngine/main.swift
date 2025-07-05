//
//  main.swift
//  ChessEngine
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation

var board = ChessBoard()
board.initializeNewBoard()

func main() throws {
  let args = CommandLine.arguments
  print(args)

  if args.count > 2 {
    print("Usage: {} <script>")
    exit(64)
  }
  else if args.count == 2 {
    try runFile(args[1])
  }
  else {
    try runPrompt()
  }
}

func runFile(_ path: String) throws {
  let string = try String(contentsOfFile: path, encoding:.utf8)
  run(string)
}

func runPrompt() throws {
  while true {
    print("> ", terminator: "")
    guard let line = readLine() else { break }
    run(line)
  }
}

func run(_ source: String) {
  let scanner = Tokenizer(source: source)
  let tokens = scanner.scanTokens()
  
  // for now, just print the tokens
  for token in tokens {
    switch token.type {
    case .IDENTIFIER:
      if ("show".elementsEqual(token.lexeme)) {
        print(board)
      }
      else if ("go".elementsEqual(token.lexeme)) {
        board.searchAgent.startThinking()
      }
    default:
      // do not print anything for unrecognized tokens
      break
    }
  }
}

func error(line: Int, message: String) {
  report(line: line, context:"", message: message)
}

var hadError = false

func report(line: Int, context: String, message: String) {
  print("[line: \(line)] Error: \(context) \(message)")
  hadError = true
}

try main()
