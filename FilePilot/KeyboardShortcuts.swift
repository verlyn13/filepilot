//
//  KeyboardShortcuts.swift
//  FilePilot
//
//  Keyboard shortcut definitions and handlers
//

import SwiftUI

struct KeyboardShortcuts: Commands {
    @FocusedObject var appState: AppState?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Folder") {
                createNewFolder()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandMenu("View") {
            Button("Show Hidden Files") {
                appState?.showHiddenFiles.toggle()
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])

            Divider()

            Button("List View") {
                appState?.viewMode = .list
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Grid View") {
                appState?.viewMode = .grid
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Column View") {
                appState?.viewMode = .column
            }
            .keyboardShortcut("3", modifiers: .command)
        }

        CommandMenu("Go") {
            Button("Home") {
                appState?.navigateToHome()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("Desktop") {
                appState?.navigateToDesktop()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Downloads") {
                appState?.navigateToDownloads()
            }
            .keyboardShortcut("l", modifiers: [.command, .option])

            Button("Documents") {
                appState?.navigateToDocuments()
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
        }
    }

    private func createNewFolder() {
        guard let appState = appState else { return }

        let savePanel = NSSavePanel()
        savePanel.title = "New Folder"
        savePanel.prompt = "Create"
        savePanel.nameFieldLabel = "Folder Name:"
        savePanel.nameFieldStringValue = "New Folder"
        savePanel.directoryURL = appState.currentPath

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                print("Failed to create folder: \(error)")
            }
        }
    }
}