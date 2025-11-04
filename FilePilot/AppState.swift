//
//  AppState.swift
//  FilePilot
//
//  Application state management
//

import SwiftUI
import Foundation

enum ViewMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
    case column = "Column"
}

class AppState: ObservableObject {
    @Published var currentPath: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var selectedItems: Set<URL> = []
    @Published var viewMode: ViewMode = .list
    @Published var showHiddenFiles = false
    @Published var sortOrder: FileManager.DirectoryEnumerationOptions = []
    @Published var isLoading = false
    @Published var error: Error?

    // Git related
    @Published var isGitRepository = false
    @Published var hasUnstagedChanges = false
    @Published var hasStagedChanges = false
    @Published var hasGitHubRemote = false
    @Published var showGoToPath = false
    @Published var showCommitDialog = false

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

    func navigateToDocuments() {
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            currentPath = documents
            TelemetryService.shared.recordNavigation(to: documents)
        }
    }

    func navigateTo(url: URL) {
        currentPath = url
        TelemetryService.shared.recordNavigation(to: url)
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
}