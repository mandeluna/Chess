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
    @StateObject private var settings = ChessSettings()

    var body: some Scene {
        WindowGroup {
            ChessView()
                .environmentObject(gameState)
                .environmentObject(settings)
                .onAppear {
                    gameState.attach(settings: settings)
                }
        }
    }
}
