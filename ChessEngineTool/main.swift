//
//  main.swift
//  ChessEngine
//
//  Created by Steve Wart on 2025-07-03.
//

import Foundation

UserDefaults.standard.register(defaults: [
    debug_level_key: debug_level_verbose
])

class Application {
    let controller = ChessEngineController()
    let logger = Logger.default()!
    
    func run() {
        let args = CommandLine.arguments
        let currentDebugLevel = UserDefaults.standard.string(forKey: debug_level_key)
        if currentDebugLevel == debug_level_none {
            logger.level = None
        }
        else {
            logger.level = Error
        }
        
        let date = Date.now
        logger.logMessage("started Chamonix at \(date.ISO8601Format())")
        logger.logMessage("arguments: " + args.joined(separator: " "))
        
        if args.count > 2 {
            print("Usage: {} <script>")
            exit(64)
        }
        else if args.count == 2 {
            processFileInput(path: args[1])
        }
        else {
            processInteractiveInput()
        }
    }
    
    func processFileInput(path: String) {
        do {
            let string = try String(contentsOfFile: path, encoding:.utf8)
            let lines = string.components(separatedBy: "\n")
            for line in lines {
                let command = line.trimmingCharacters(in: .whitespacesAndNewlines)
                logger.logMessage("< \(command)")
                controller.processCommand(command)
                
                // Handle synchronous commands that might block
                if command.hasPrefix("go") {
                    // Wait a bit for search to potentially start
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            // don't return until all requests have been processed
            controller.waitForReady()
        } catch {
            print("Error: Could not read file '\(path)': \(error)")
            exit(1)
        }
    }
    
    func processInteractiveInput() {

        setupSignalHandlers()

        DispatchQueue.global(qos: .utility).async { [weak self] in
            while true {
                guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let self = self
                else { continue }
                
                if input.lowercased() == "quit" {
                    exit(0)
                }
                
                logger.logMessage("< \(input)")
                self.processCommand(input)
            }
        }

        // Keep main thread alive
        RunLoop.current.run()
    }
    
    private func processCommand(_ input: String) {
        // Use a serial queue for thread-safe command processing
        DispatchQueue.main.async {
            self.controller.processCommand(input)
        }
    }
    
    private func setupSignalHandlers() {
        // Handle Ctrl+C gracefully
        signal(SIGINT) { _ in
            print("\nReceived interrupt signal, shutting down...")
            exit(0)
        }
    }
}

let app = Application()
app.run()
