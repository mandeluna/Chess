//
//  main.swift
//  ChessEngine
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation

private var engine = ChessEngineController()

func main() throws {
    let args = CommandLine.arguments

    let date = Date.now
    logDebug("started Chamonix at \(date.ISO8601Format())")
    logDebug("arguments: " + args.joined(separator: " "))
    
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
    let lines = string.components(separatedBy: "\n")
    for line in lines {
        print("line: \(line)")
        engine.processCommand(line)
        
    }
}

func runPrompt() throws {
    while true {
        if let line = readLine() {
            logDebug("received: " + line)
            engine.processCommand(line)
        }
    }
}

try main()
