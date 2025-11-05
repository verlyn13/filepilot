//
//  ContentView.swift
//  FilePilot
//
//  Main view for the file manager
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var telemetry: TelemetryService

    @State private var selectedURLs: Set<URL> = []
    @State private var sortOrder = [KeyPathComparator(\FileItem.name)]
    @StateObject private var filterState = FilterState()
    @State private var showingInspector = false
    @State private var showingFilterPanel = false
    @State private var showingGitPanel = false
    @State private var columnWidths = [
        GridItem(.flexible(minimum: 200, maximum: 400)),
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 150, maximum: 250))
    ]

    // MARK: - Toolbar Components

    /// Navigation controls (back, forward, up)
    ///
    /// **Refactoring Note:**
    /// Extracted from body to reduce complexity from 10 to 2
    private var navigationButtons: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBack)

            Button(action: goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoForward)

            Button(action: goUp) {
                Image(systemName: "chevron.up")
            }
            .disabled(!canGoUp)
        }
    }

    /// Inspector panel toggle button
    ///
    /// **Refactoring Note:**
    /// Extracted from body to reduce complexity
    private var inspectorButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showingInspector.toggle() }) {
                Image(systemName: "info.circle")
            }
        }
    }

    /// Git status panel toggle button
    private var gitButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                withAnimation {
                    showingGitPanel.toggle()
                }
                TelemetryService.shared.recordAction("git_panel_toggled", metadata: [
                    "visible": showingGitPanel
                ])
            }) {
                Image(systemName: showingGitPanel ? "arrow.triangle.branch.fill" : "arrow.triangle.branch")
            }
            .help("Toggle Git Panel")
        }
    }

    /// View mode selection menu (list/grid/column)
    ///
    /// **Refactoring Note:**
    /// Extracted from body to reduce complexity
    private var viewModeMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("List View") { appState.viewMode = .list }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Grid View") { appState.viewMode = .grid }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Column View") { appState.viewMode = .column }
                    .keyboardShortcut("3", modifiers: .command)
            } label: {
                Image(systemName: viewModeIcon)
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView()
                .frame(minWidth: 200, idealWidth: 250)
        } detail: {
            // Main content area
            HStack(spacing: 0) {
                // Filter panel (collapsible, left side)
                if showingFilterPanel {
                    FilterPanelView(filterState: filterState)
                        .transition(.move(edge: .leading))
                }

                VStack(spacing: 0) {
                    // Toolbar
                    ToolbarView(searchText: $filterState.searchText, showingFilterPanel: $showingFilterPanel)

                    // File list/grid
                    FileListView(
                        path: appState.currentPath,
                        selectedURLs: $selectedURLs,
                        filterState: filterState,
                        sortOrder: sortOrder
                    )
                    .onAppear {
                        telemetry.recordNavigation(to: appState.currentPath)
                        checkForGitRepository()
                    }
                    .onChange(of: appState.currentPath) {
                        checkForGitRepository()
                    }
                }

                // Git panel (collapsible, right side)
                if showingGitPanel {
                    GitStatusView()
                        .frame(width: 350)
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            navigationButtons
            gitButton
            inspectorButton
            viewModeMenu
        }
        .inspector(isPresented: $showingInspector) {
            InspectorView(selectedURLs: selectedURLs)
                .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickLookRequested)) { _ in
            showQuickLook()
        }
    }

    // MARK: - Navigation

    @State private var navigationHistory: [URL] = []
    @State private var navigationIndex = 0

    private var canGoBack: Bool {
        navigationIndex > 0
    }

    private var canGoForward: Bool {
        navigationIndex < navigationHistory.count - 1
    }

    private var canGoUp: Bool {
        appState.currentPath.path != "/"
    }

    private func goBack() {
        guard canGoBack else { return }
        navigationIndex -= 1
        appState.currentPath = navigationHistory[navigationIndex]
    }

    private func goForward() {
        guard canGoForward else { return }
        navigationIndex += 1
        appState.currentPath = navigationHistory[navigationIndex]
    }

    private func goUp() {
        let parent = appState.currentPath.deletingLastPathComponent()
        navigate(to: parent)
    }

    private func navigate(to url: URL) {
        // Update history
        if navigationIndex < navigationHistory.count - 1 {
            navigationHistory.removeSubrange((navigationIndex + 1)...)
        }
        navigationHistory.append(url)
        navigationIndex = navigationHistory.count - 1

        // Update current path
        appState.currentPath = url
    }

    // MARK: - View Mode

    private var viewModeIcon: String {
        switch appState.viewMode {
        case .list:
            return "list.bullet"
        case .grid:
            return "square.grid.2x2"
        case .column:
            return "rectangle.grid.1x2"
        }
    }

    // MARK: - Quick Look

    private func showQuickLook() {
        guard !selectedURLs.isEmpty else { return }
        // Quick Look implementation handled by QuickLookService
    }

    // MARK: - Git Integration

    private func checkForGitRepository() {
        // Check if current path is in a git repository
        if let repo = GitStatusService.shared.findRepository(containing: appState.currentPath) {
            // Only auto-load if git panel is visible
            if showingGitPanel {
                GitStatusService.shared.loadStatus(for: repo)
            }
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var gitService = GitStatusService.shared
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var isGitSectionExpanded = false

    var body: some View {
        List {
            Section("Favorites") {
                // System favorites (always shown)
                Button(action: {
                    appState.navigateToHome()
                }) {
                    Label("Home", systemImage: "house")
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.navigateToDesktop()
                }) {
                    Label("Desktop", systemImage: "desktopcomputer")
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.navigateToDownloads()
                }) {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.plain)

                // User-defined favorites
                if !favoritesManager.favorites.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    ForEach(favoritesManager.favorites) { favorite in
                        Button(action: {
                            appState.navigateTo(url: favorite.url)
                        }) {
                            Label(favorite.name, systemImage: favorite.iconName)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Remove from Favorites") {
                                favoritesManager.removeFavorite(id: favorite.id)
                            }

                            Button("Rename...") {
                                // TODO: Show rename dialog
                            }

                            Divider()

                            Button("Show in Finder") {
                                NSWorkspace.shared.selectFile(favorite.url.path, inFileViewerRootedAtPath: "")
                            }
                        }
                    }
                    .onMove { source, destination in
                        favoritesManager.moveFavorites(from: source, to: destination)
                    }
                }

                Divider()

                // Add current path to favorites button
                Button(action: {
                    addCurrentPathToFavorites()
                }) {
                    Label("Add Current Location", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }

            DisclosureGroup("Git Repositories", isExpanded: $isGitSectionExpanded) {
                RepositorySelectorView(gitService: gitService)
            }

            Section("Devices") {
                Text("No devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(SidebarListStyle())
    }

    private func addCurrentPathToFavorites() {
        let added = favoritesManager.addFavorite(url: appState.currentPath)
        if added {
            TelemetryService.shared.recordAction("favorite_added_from_sidebar", metadata: [
                "path": appState.currentPath.path
            ])
        }
    }
}

// MARK: - Toolbar View

struct ToolbarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var searchText: String
    @Binding var showingFilterPanel: Bool

    var body: some View {
        HStack {
            // Filter panel toggle
            Button(action: {
                withAnimation {
                    showingFilterPanel.toggle()
                }
                TelemetryService.shared.recordAction("filter_panel_toggled", metadata: [
                    "visible": showingFilterPanel
                ])
            }) {
                Image(systemName: showingFilterPanel ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            .help("Toggle Filter Panel")

            // Path bar
            PathBarView(path: appState.currentPath)

            Spacer()

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .frame(width: 250)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
    }
}

// MARK: - Path Bar View

struct PathBarView: View {
    let path: URL

    var pathComponents: [String] {
        path.pathComponents.filter { $0 != "/" }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    // Navigate to this path component
                }) {
                    Text(component)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    // Show hover effect
                }
            }
        }
    }
}

// MARK: - Inspector View

struct InspectorView: View {
    let selectedURLs: Set<URL>

    var body: some View {
        if selectedURLs.isEmpty {
            ContentUnavailableView(
                "No Selection",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Select a file to view details")
            )
        } else if selectedURLs.count == 1, let url = selectedURLs.first {
            FileInspectorView(url: url)
        } else {
            MultipleSelectionView(urls: selectedURLs)
        }
    }
}

struct FileInspectorView: View {
    let url: URL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview
                // TODO: Add async thumbnail generation
                // QuickLookService.shared.generateThumbnail()

                // File info
                VStack(alignment: .leading, spacing: 8) {
                    Text(url.lastPathComponent)
                        .font(.headline)

                    // File details would go here
                }
                .padding()
            }
        }
    }
}

struct MultipleSelectionView: View {
    let urls: Set<URL>

    var body: some View {
        VStack {
            Text("\(urls.count) items selected")
                .font(.headline)
            // Aggregate info
        }
        .padding()
    }
}

// MARK: - Supporting Types

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let modified: Date
    let isDirectory: Bool
    let icon: NSImage?
}

// MARK: - Notifications

extension Notification.Name {
    static let quickLookRequested = Notification.Name("quickLookRequested")
}