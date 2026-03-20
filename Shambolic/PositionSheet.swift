//
//  PositionSheet.swift
//  Shambolic
//
//  Created by Steve Wart on 2026-03-19.
//

import SwiftUI

struct PositionSheet: View {
    @EnvironmentObject var gameState: ChessGame
    @Environment(\.dismiss) private var dismiss

    @State private var fenText = ""
    @State private var showAbandonConfirmation = false
    @State private var confirmedFEN = ""

    private var shareText: String {
        if gameState.pgn.isEmpty {
            return fenText
        }
        return "\(gameState.pgn)\n\nFEN: \(fenText)"
    }

    // Lichess analysis URL: piece placement uses / as rank separator (URL path segments),
    // remaining FEN fields are joined with _ instead of spaces.
    private var lichessURL: URL? {
        let fen = fenText.trimmingCharacters(in: .whitespaces)
        let parts = fen.components(separatedBy: " ")
        guard let placement = parts.first, !placement.isEmpty else { return nil }
        let rest = parts.dropFirst().joined(separator: "_")
        let path = rest.isEmpty ? placement : "\(placement)_\(rest)"
        return URL(string: "https://lichess.org/analysis/\(path)")
    }

    private var canLoad: Bool {
        !fenText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Position (FEN)") {
                    TextEditor(text: $fenText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 88)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Share") {
                    ShareLink(
                        item: shareText,
                        subject: Text("Chess Position")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    if let url = lichessURL {
                        Link(destination: url) {
                            Label("Open in Lichess", systemImage: "arrow.up.right.square")
                        }
                    }
                }

                Section {
                    Button("Load Position") {
                        let fen = fenText.trimmingCharacters(in: .whitespaces)
                        guard !fen.isEmpty else { return }
                        if gameState.isInInitialPosition {
                            gameState.loadFEN(fen)
                            dismiss()
                        } else {
                            confirmedFEN = fen
                            showAbandonConfirmation = true
                        }
                    }
                    .disabled(!canLoad)
                }
            }
            .navigationTitle("Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                fenText = gameState.currentFEN
            }
            .alert("Abandon current game?", isPresented: $showAbandonConfirmation) {
                Button("Load Position", role: .destructive) {
                    gameState.loadFEN(confirmedFEN)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Loading a new position will end the current game.")
            }
        }
    }
}

#Preview {
    PositionSheet()
        .environmentObject(ChessGame())
}
