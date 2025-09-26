//
//  SettingsView.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-24.
//
import Combine
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = ChessSettings()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Analysis Section
                    analysisSection
                    
                    // Engine Performance Section
                    enginePerformanceSection
                    
                    // Game Preferences Section
                    gamePreferencesSection
                    
                    // Visual Settings Section
                    visualSettingsSection
                    
                    // Reset Section
                    resetSection
                }
                .padding()
            }
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Analysis Section
    
    private var analysisSection: some View {
        CardView(title: "Analysis", icon: "chart.bar") {
            VStack(spacing: 16) {
                ToggleRow(
                    icon: "cloud",
                    title: "Online Analysis",
                    subtitle: "Get expert evaluation from Lichess servers",
                    isOn: $settings.enableOnlineAnalysis
                )
                
                if settings.enableOnlineAnalysis {
                    InfoRow(
                        icon: "info.circle",
                        text: "Requires internet connection. Positions are analyzed anonymously."
                    )
                    .foregroundColor(.secondary)
                }
                
                ToggleRow(
                    icon: "brain",
                    title: "Local Engine Analysis",
                    subtitle: "Use device's engine for instant evaluation",
                    isOn: $settings.enableLocalAnalysis
                )
                
                StepperRow(
                    icon: "gauge",
                    title: "Analysis Depth",
                    subtitle: "Deeper analysis finds better moves but takes longer",
                    value: $settings.analysisDepth,
                    range: 1...25,
                    format: "Level %d"
                )
            }
        }
    }
    
    // MARK: - Engine Performance Section
    
    private var enginePerformanceSection: some View {
        CardView(title: "Engine Performance", icon: "speedometer") {
            VStack(spacing: 16) {
                StepperRow(
                    icon: "memorychip",
                    title: "Engine Memory",
                    subtitle: "More memory helps engine remember positions and think deeper",
                    value: $settings.hashSize,
                    range: 16...512,
                    format: "%d MB"
                )
                
                InfoRow(
                    icon: "info.circle",
                    text: "Higher values use more device memory but improve engine strength."
                )
                .foregroundColor(.secondary)
                
                PickerRow(
                    icon: "atom",
                    title: "Thinking Time",
                    subtitle: "How long engine thinks before moving",
                    selection: $settings.thinkingTime,
                    options: [
                        "Quick (1-3 sec)",
                        "Standard (3-10 sec)",
                        "Deep (10-30 sec)",
                        "Tournament (30+ sec)"
                    ]
                )
                
                ToggleRow(
                    icon: "sparkles",
                    title: "Smart Pruning",
                    subtitle: "Skip analyzing obviously bad moves to think faster",
                    isOn: $settings.enablePruning
                )
            }
        }
    }
    
    // MARK: - Game Preferences Section
    
    private var gamePreferencesSection: some View {
        CardView(title: "Game Preferences", icon: "gamecontroller") {
            VStack(spacing: 16) {
                ToggleRow(
                    icon: "cursorarrow.motionlines",
                    title: "Show Legal Moves",
                    subtitle: "Highlight squares where selected piece can move",
                    isOn: $settings.showLegalMoves
                )
                
                ToggleRow(
                    icon: "exclamationmark.triangle",
                    title: "Highlight Checks",
                    subtitle: "Warn when king is in danger",
                    isOn: $settings.highlightChecks
                )
                
                ToggleRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Animation Effects",
                    subtitle: "Smooth piece movements and transitions",
                    isOn: $settings.enableAnimations
                )
                
                PickerRow(
                    icon: "speaker.wave.2",
                    title: "Move Sound",
                    subtitle: "Sound effects during gameplay",
                    selection: $settings.moveSound,
                    options: ["None", "Subtle", "Classic", "Modern"]
                )
            }
        }
    }
    
    // MARK: - Visual Settings Section
    
    private var visualSettingsSection: some View {
        CardView(title: "Appearance", icon: "paintbrush") {
            VStack(spacing: 16) {
                PickerRow(
                    icon: "square.grid.2x2",
                    title: "Board Theme",
                    subtitle: "Color scheme for the chessboard",
                    selection: $settings.boardTheme,
                    options: ["Classic Green", "Wooden", "Marble", "Dark", "Blue"]
                )
                
                PickerRow(
                    icon: "circle.grid.cross",
                    title: "Piece Style",
                    subtitle: "Visual design of chess pieces",
                    selection: $settings.pieceStyle,
                    options: ["Classic", "Modern", "Minimal", "3D"]
                )
                
                ToggleRow(
                    icon: "sun.max",
                    title: "Dark Mode",
                    subtitle: "Use dark theme for the interface",
                    isOn: $settings.useDarkMode
                )
            }
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        CardView(title: "Reset", icon: "arrow.clockwise") {
            VStack(spacing: 12) {
                Button(action: settings.resetToDefaults) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Default Settings")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                InfoRow(
                    icon: "info.circle",
                    text: "This will restore all settings to their original values."
                )
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct CardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct StepperRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let format: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: format, value))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Stepper("", value: $value, in: range)
                    .labelsHidden()
            }
        }
    }
}

struct PickerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Settings Model

class ChessSettings: ObservableObject {
    @Published var enableOnlineAnalysis: Bool = true
    @Published var enableLocalAnalysis: Bool = true
    @Published var analysisDepth: Int = 18
    
    @Published var hashSize: Int = 128
    @Published var thinkingTime: String = "Standard (3-10 sec)"
    @Published var enablePruning: Bool = true
    
    @Published var showLegalMoves: Bool = true
    @Published var highlightChecks: Bool = true
    @Published var enableAnimations: Bool = true
    @Published var moveSound: String = "Subtle"
    
    @Published var boardTheme: String = "Classic Green"
    @Published var pieceStyle: String = "Classic"
    @Published var useDarkMode: Bool = false
    
    func resetToDefaults() {
        enableOnlineAnalysis = true
        enableLocalAnalysis = true
        analysisDepth = 18
        
        hashSize = 128
        thinkingTime = "Standard (3-10 sec)"
        enablePruning = true
        
        showLegalMoves = true
        highlightChecks = true
        enableAnimations = true
        moveSound = "Subtle"
        
        boardTheme = "Classic Green"
        pieceStyle = "Classic"
        useDarkMode = false
    }
}

// MARK: - Preview

#Preview("Settings View") {
    SettingsView()
}

#Preview("Settings View Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}
