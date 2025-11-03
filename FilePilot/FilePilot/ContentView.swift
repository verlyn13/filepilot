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
    @State private var searchText = ""
    @State private var showingInspector = false
    @State private var columnWidths = [
        GridItem(.flexible(minimum: 200, maximum: 400)),
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 100, maximum: 200)),
        GridItem(.flexible(minimum: 150, maximum: 250))
    ]

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView()
                .frame(minWidth: 200, idealWidth: 250)
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView(searchText: $searchText)

                // File list/grid
                FileListView(
                    path: appState.currentPath,
                    selectedURLs: $selectedURLs,
                    searchText: searchText,
                    sortOrder: sortOrder
                )
                .onAppear {
                    telemetry.recordNavigation(to: appState.currentPath)
                }
            }
        }
        .navigationTitle("")
        .toolbar {
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

            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingInspector.toggle() }) {
                    Image(systemName: "info.circle")
                }
            }

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
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section("Favorites") {
                NavigationLink(destination: EmptyView()) {
                    Label("Home", systemImage: "house")
                }
                .onTapGesture {
                    appState.navigateToHome()
                }

                NavigationLink(destination: EmptyView()) {
                    Label("Desktop", systemImage: "desktopcomputer")
                }
                .onTapGesture {
                    appState.navigateToDesktop()
                }

                NavigationLink(destination: EmptyView()) {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
                .onTapGesture {
                    appState.navigateToDownloads()
                }
            }

            Section("Git Repositories") {
                // Populated dynamically based on discovered repos
                ForEach(GitService.shared.repositories, id: \.self) { repo in
                    NavigationLink(destination: EmptyView()) {
                        Label(repo.lastPathComponent, systemImage: "folder.badge.gearshape")
                    }
                    .onTapGesture {
                        appState.currentPath = repo
                    }
                }
            }

            Section("Devices") {
                // External volumes, network shares, etc.
            }
        }
        .listStyle(SidebarListStyle())
    }
}

// MARK: - Toolbar View

struct ToolbarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var searchText: String

    var body: some View {
        HStack {
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
            .frame(width: 200)
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
                if let thumbnail = try? QuickLookService.shared.generateThumbnail(
                    for: url,
                    size: CGSize(width: 200, height: 200)
                ) {
                    // Show thumbnail
                }

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

// MARK: - Git Service Stub

class GitService: ObservableObject {
    static let shared = GitService()

    @Published var repositories: [URL] = []

    init() {
        discoverRepositories()
    }

    private func discoverRepositories() {
        // Scan common locations for git repos
        // This is a simplified version
        let home = FileManager.default.homeDirectoryForCurrentUser
        let devPaths = [
            home.appendingPathComponent("Development"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Documents/GitHub")
        ]

        for path in devPaths {
            findGitRepos(in: path)
        }
    }

    private func findGitRepos(in directory: URL) {
        // Simplified git repo detection
        // In production, use FSEvents and proper traversal
    }
}