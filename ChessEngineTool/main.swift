//
//  main.swift
//  ChessEngine
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation
import LineNoise

private var engine = ChessEngineController()

var debug_path = "/tmp/engine_debug.log"

let filemanager = FileManager.default
if !filemanager.fileExists(atPath: debug_path) {
    filemanager.createFile(atPath: debug_path, contents: nil)
}
var log = FileHandle(forWritingAtPath: "/tmp/engine_debug.log") ?? FileHandle.standardError

func debugPrint(_ str: String) {
    log.write("\(str)\n".data(using: .utf8)!)
    do {
        try log.synchronize()
    } catch {
        log.write("\(error)\n".data(using: .utf8)!)
    }
}

func main() throws {
    let args = CommandLine.arguments

    let date = Date.now
    debugPrint("started Chamonix at \(date.ISO8601Format())")
    debugPrint("arguments: " + args.joined(separator: " "))
    
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
    engine.processCommand(string)
}

func runPrompt() throws {
    
    while true {
        if let line = readLine() {
            debugPrint("received: " + line)
            engine.processCommand(line)
        }
    }
}

try main()
