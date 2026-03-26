//
//  SettingsView.swift
//  Shambolic
//
//  Created by Steve Wart on 2025-09-24.
//

import Combine
import ChessEngine
import SwiftUI

// MARK: - Settings Model

class ChessSettings: ObservableObject {

    // MARK: Engine

    /// How long the engine thinks per move (seconds). Ignored when depthLimit > 0.
    @Published var moveTimeSecs: Double {
        didSet { UserDefaults.standard.set(moveTimeSecs, forKey: Keys.moveTimeSecs) }
    }

    /// Maximum search depth. 0 = time-limited (default). Capped at 10 to prevent
    /// indefinitely long searches — depth 8+ can take several minutes in complex positions.
    @Published var depthLimit: Int {
        didSet { UserDefaults.standard.set(depthLimit, forKey: Keys.depthLimit) }
    }

    /// Transposition table size in MB. Larger values improve search quality at the cost
    /// of device memory. 128 MB is a good default for most devices.
    @Published var hashSizeMB: Int {
        didSet { UserDefaults.standard.set(hashSizeMB, forKey: Keys.hashSizeMB) }
    }

    // MARK: Game

    @Published var showLegalMoves: Bool {
        didSet { UserDefaults.standard.set(showLegalMoves, forKey: Keys.showLegalMoves) }
    }

    @Published var highlightChecks: Bool {
        didSet { UserDefaults.standard.set(highlightChecks, forKey: Keys.highlightChecks) }
    }

    // MARK: Appearance (placeholders — wired when assets are available)

    /// Board color scheme identifier. Currently informational; the board uses a fixed theme.
    @Published var boardTheme: String {
        didSet { UserDefaults.standard.set(boardTheme, forKey: Keys.boardTheme) }
    }

    // pieceSet: String — future, pending CC-licensed piece set assets

    // MARK: - Private

    private enum Keys {
        static let moveTimeSecs  = "engine.moveTimeSecs"
        static let depthLimit    = "engine.depthLimit"
        static let hashSizeMB    = "engine.hashSizeMB"
        static let showLegalMoves = "game.showLegalMoves"
        static let highlightChecks = "game.highlightChecks"
        static let boardTheme    = "appearance.boardTheme"
    }

    init() {
        let d = UserDefaults.standard
        moveTimeSecs  = d.object(forKey: Keys.moveTimeSecs)  as? Double ?? 5.0
        depthLimit    = d.object(forKey: Keys.depthLimit)    as? Int    ?? 0
        hashSizeMB    = d.object(forKey: Keys.hashSizeMB)   as? Int    ?? 128
        showLegalMoves = d.object(forKey: Keys.showLegalMoves) as? Bool ?? true
        highlightChecks = d.object(forKey: Keys.highlightChecks) as? Bool ?? true
        boardTheme    = d.string(forKey: Keys.boardTheme)           ?? "green"
    }

    /// UCI parameter dict to pass to the engine for a game search.
    var uciSearchParams: [String: Any] {
        if depthLimit > 0 {
            return ["depth": depthLimit]
        }
        return ["movetime": Int(moveTimeSecs * 1000)]
    }

    func resetToDefaults() {
        moveTimeSecs  = 5.0
        depthLimit    = 0
        hashSizeMB    = 128
        showLegalMoves  = true
        highlightChecks = true
        boardTheme    = "green"
    }
}

// MARK: - View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: ChessSettings

    private let hashOptions = [32, 64, 128, 256, 512]
    private let timeOptions: [(label: String, secs: Double)] = [
        ("1s", 1), ("3s", 3), ("5s", 5), ("10s", 10), ("30s", 30)
    ]

    var body: some View {
        NavigationStack {
            Form {
                engineSection
                gameSection
                appearanceSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") { settings.resetToDefaults() }
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: Engine

    private var engineSection: some View {
        Section {
            timeLimitRow
            depthCapRow
            hashSizeRow
        } header: {
            Text("Engine")
        } footer: {
            if settings.depthLimit > 0 {
                Text("Time limit is ignored when a depth cap is set. Depths above 8 may take several minutes in complex positions.")
            } else {
                Text("The engine searches until time is up, then plays the best move found.")
            }
        }
    }

    private var timeLimitRow: some View {
        Picker("Time limit", selection: $settings.moveTimeSecs) {
            ForEach(timeOptions, id: \.secs) { option in
                Text(option.label).tag(option.secs)
            }
        }
        .disabled(settings.depthLimit > 0)
    }

    private var depthCapRow: some View {
        Stepper(value: $settings.depthLimit, in: 0...10) {
            LabeledContent("Depth cap") {
                Text(settings.depthLimit == 0 ? "Off" : "\(settings.depthLimit)")
                    .foregroundStyle(settings.depthLimit == 0 ? .secondary : .primary)
            }
        }
    }

    private var hashSizeRow: some View {
        Picker("Hash memory", selection: $settings.hashSizeMB) {
            ForEach(hashOptions, id: \.self) { mb in
                Text("\(mb) MB").tag(mb)
            }
        }
    }

    // MARK: Game

    private var gameSection: some View {
        Section("Game") {
            Toggle("Show legal moves", isOn: $settings.showLegalMoves)
            Toggle("Highlight checks", isOn: $settings.highlightChecks)
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section {
            LabeledContent("Board") {
                Text("Classic").foregroundStyle(.secondary)
            }
            LabeledContent("Pieces") {
                Text("Classic (built-in)").foregroundStyle(.secondary)
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Additional board themes and CC-licensed piece sets will be available in a future update.")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            LabeledContent("Engine") {
                Text("\(ChessEngineInfo.displayName) \(ChessEngineInfo.version) build \(ChessEngineInfo.buildNumber) (built-in)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Support for alternative UCI-compatible engines is planned.")
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
        .environmentObject(ChessSettings())
}

#Preview("Settings Dark") {
    SettingsView()
        .environmentObject(ChessSettings())
        .preferredColorScheme(.dark)
}
