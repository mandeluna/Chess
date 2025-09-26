//
//  ShambolicApp.swift
//  Shambolic
//
//  Created by Steve Wart on 2025-09-25.
//

import SwiftUI

@main
struct ShambolicApp: App {
    @StateObject private var gameState = ChessGame()

    var body: some Scene {
        WindowGroup {
            ChessView()
                .environmentObject(gameState)
        }
    }
}
