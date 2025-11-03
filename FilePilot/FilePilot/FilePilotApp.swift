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
    @StateObject private var telemetry = TelemetryService.shared

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
            // File menu additions
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

            // View menu
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

            // Go menu
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

            // Git menu
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

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var currentPath: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var selectedItems: Set<URL> = []
    @Published var viewMode: ViewMode = .list
    @Published var showHiddenFiles = false
    @Published var isGitRepository = false
    @Published var hasUnstagedChanges = false
    @Published var hasStagedChanges = false
    @Published var hasGitHubRemote = false
    @Published var showGoToPath = false
    @Published var showCommitDialog = false

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case grid = "Grid"
        case column = "Column"
    }

    init() {
        checkGitStatus()
        startFileWatching()
    }

    func openNewWindow() {
        // Implementation for opening new window
        TelemetryService.shared.recordAction("new_window")
    }

    func openNewTab() {
        // Implementation for opening new tab
        TelemetryService.shared.recordAction("new_tab")
    }

    func toggleHiddenFiles() {
        showHiddenFiles.toggle()
        TelemetryService.shared.recordAction("toggle_hidden_files", metadata: ["show": showHiddenFiles])
    }

    func navigateToHome() {
        currentPath = FileManager.default.homeDirectoryForCurrentUser
        TelemetryService.shared.recordNavigation(to: currentPath)
    }

    func navigateToDesktop() {
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            currentPath = desktop
            TelemetryService.shared.recordNavigation(to: desktop)
        }
    }

    func navigateToDownloads() {
        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            currentPath = downloads
            TelemetryService.shared.recordNavigation(to: downloads)
        }
    }

    func showGitStatus() {
        // Implementation for showing git status
        TelemetryService.shared.recordAction("show_git_status")
    }

    func stageChanges() {
        // Implementation for staging changes
        TelemetryService.shared.recordAction("stage_changes")
    }

    func openOnGitHub() {
        // Implementation for opening on GitHub
        TelemetryService.shared.recordAction("open_github")
    }

    private func checkGitStatus() {
        // Check if current directory is a git repository
        let gitPath = currentPath.appendingPathComponent(".git")
        isGitRepository = FileManager.default.fileExists(atPath: gitPath.path)
    }

    private func startFileWatching() {
        // Start FSEvents monitoring
        // This will be implemented in FSEventsService
    }
}

// MARK: - Telemetry Service

class TelemetryService: ObservableObject {
    static let shared = TelemetryService()

    private let apiURL = URL(string: "http://localhost:3000/api/telemetry")!

    func recordAppLaunch() {
        sendEvent("app_launch", metadata: [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }

    func recordAction(_ action: String, metadata: [String: Any]? = nil) {
        sendEvent("user_action", metadata: ["action": action] + (metadata ?? [:]))
    }

    func recordNavigation(to url: URL) {
        sendEvent("navigation", metadata: ["path": url.path])
    }

    func recordError(_ error: Error, context: String) {
        sendEvent("error", metadata: [
            "error": error.localizedDescription,
            "context": context
        ])
    }

    private func sendEvent(_ event: String, metadata: [String: Any]) {
        // Send telemetry to our TypeScript backend
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "event": event,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "metadata": metadata
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = data
            URLSession.shared.dataTask(with: request).resume()
        }
    }
}

// Helper to merge dictionaries
extension Dictionary {
    static func +(lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        var result = lhs
        for (key, value) in rhs {
            result[key] = value
        }
        return result
    }
}