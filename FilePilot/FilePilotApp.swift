//
//  FilePilotApp.swift
//  FilePilot
//
//  A developer-centric file manager for macOS with Quick Look, Git integration, and power-user features.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct FilePilotApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var telemetry = TelemetryService.shared

    // MARK: - Menu Command Groups

    /// File menu commands (New Window, New Tab)
    ///
    /// **Refactoring Note:**
    /// - Original complexity: Combined in body (10)
    /// - Refactored complexity: 1 per command group
    /// - Improvement: Separated menu logic from scene configuration
    @CommandsBuilder
    private var fileMenuCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                appState.openNewWindow()
            }
            .keyboardShortcut("N", modifiers: [.command])

            Button("New Tab") {
                appState.openNewTab()
            }
            .keyboardShortcut("T", modifiers: [.command])
        }
    }

    /// View menu commands (Hidden files, View modes)
    @CommandsBuilder
    private var viewMenuCommands: some Commands {
        CommandMenu("View") {
            Button("Show Hidden Files") {
                appState.toggleHiddenFiles()
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])

            Divider()

            Button("List View") {
                appState.viewMode = .list
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Grid View") {
                appState.viewMode = .grid
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Column View") {
                appState.viewMode = .column
            }
            .keyboardShortcut("3", modifiers: [.command])
        }
    }

    /// Go menu commands (Navigation shortcuts)
    @CommandsBuilder
    private var goMenuCommands: some Commands {
        CommandMenu("Go") {
            Button("Home") {
                appState.navigateToHome()
            }
            .keyboardShortcut("H", modifiers: [.command, .shift])

            Button("Desktop") {
                appState.navigateToDesktop()
            }
            .keyboardShortcut("D", modifiers: [.command, .shift])

            Button("Downloads") {
                appState.navigateToDownloads()
            }
            .keyboardShortcut("L", modifiers: [.command, .option])

            Divider()

            Button("Go to Path...") {
                appState.showGoToPath = true
            }
            .keyboardShortcut("G", modifiers: [.command, .shift])
        }
    }

    /// Git menu commands (Status, Commit, GitHub integration)
    @CommandsBuilder
    private var gitMenuCommands: some Commands {
        CommandMenu("Git") {
            Button("Show Git Status") {
                appState.showGitStatus()
            }
            .keyboardShortcut("G", modifiers: [.command])
            .disabled(!appState.isGitRepository)

            Button("Stage Changes") {
                appState.stageChanges()
            }
            .disabled(!appState.hasUnstagedChanges)

            Button("Commit...") {
                appState.showCommitDialog = true
            }
            .keyboardShortcut("K", modifiers: [.command, .option])
            .disabled(!appState.hasStagedChanges)

            Divider()

            Button("Open on GitHub") {
                appState.openOnGitHub()
            }
            .disabled(!appState.hasGitHubRemote)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(telemetry)
                .onAppear {
                    telemetry.recordAppLaunch()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            fileMenuCommands
            viewMenuCommands
            goMenuCommands
            gitMenuCommands
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}