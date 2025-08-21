//
//  main.swift
//  ChessEngine
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation

private var engine = ChessEngineController()

let logger = Logger.default()!

UserDefaults.standard.register(defaults: [
    debug_level_key: debug_level_verbose
])

func main() throws {
    let args = CommandLine.arguments
    let currentDebugLevel = UserDefaults.standard.string(forKey: debug_level_key)
    if currentDebugLevel == debug_level_none {
        logger.level = None
    }
    else {
        logger.level = Verbose
    }
    
    let date = Date.now
    logger.logMessage("started Chamonix at \(date.ISO8601Format())")
    logger.logMessage("arguments: " + args.joined(separator: " "))
    
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
        logger.logMessage("< \(line)")
        engine.processCommand(line)
    }
    // don't exit the program until all requests have been processed
    engine.waitForReady()
}

func runPrompt() throws {
    while true {
        if let line = readLine() {
            logger.logMessage("< \(line)")
            engine.processCommand(line)
        }
    }
}

try main()
