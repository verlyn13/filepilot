//
//  FileListView.swift
//  FilePilot
//
//  File list display view
//

import SwiftUI

struct FileListView: View {
    let path: URL
    @Binding var selectedURLs: Set<URL>
    @ObservedObject var filterState: FilterState
    let sortOrder: [KeyPathComparator<FileItem>]

    @State private var fileItems: [FileItem] = []
    @EnvironmentObject var appState: AppState

    /// Filtered items based on all active filters
    ///
    /// Applies search, file type, date, and size filters from FilterState
    var filteredItems: [FileItem] {
        fileItems.filter { filterState.matches($0) }
    }

    /// View content based on current view mode
    ///
    /// **Refactoring Note:**
    /// - Original complexity: Combined in body (9)
    /// - Refactored complexity: 4 (viewContent) + 1 (body)
    /// - Improvement: Separated view selection from lifecycle management
    private var viewContent: some View {
        Group {
            switch appState.viewMode {
            case .list:
                listView
            case .grid:
                gridView
            case .column:
                columnView
            }
        }
    }

    var body: some View {
        viewContent
            .onAppear {
                loadFiles()
            }
            .onChange(of: path) {
                loadFiles()
            }
    }

    private var listView: some View {
        List(filteredItems, selection: $selectedURLs) { item in
            HStack {
                if let icon = item.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                Text(item.name)
                    .lineLimit(1)
                Spacer()
                if !item.isDirectory {
                    Text(FileManager.default.formattedFileSize(item.size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(item.modified, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .onTapGesture(count: 2) {
                if item.isDirectory {
                    appState.navigateTo(url: item.url)
                } else {
                    // Open file
                    NSWorkspace.shared.open(item.url)
                }
            }
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(filteredItems) { item in
                    VStack {
                        if let icon = item.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 64, height: 64)
                        }
                        Text(item.name)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .font(.caption)
                    }
                    .frame(width: 100, height: 100)
                    .onTapGesture(count: 2) {
                        if item.isDirectory {
                            appState.navigateTo(url: item.url)
                        } else {
                            NSWorkspace.shared.open(item.url)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var columnView: some View {
        // Simplified column view
        listView
    }

    private func loadFiles() {
        // Clear immediately to show loading state
        fileItems = []
        appState.isLoading = true

        // Load files on background thread to avoid UI freeze
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: self.path,
                    includingPropertiesForKeys: [.nameKey, .fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                    options: self.appState.showHiddenFiles ? [] : .skipsHiddenFiles
                )

                let items = contents.compactMap { url -> FileItem? in
                    let resourceValues = try? url.resourceValues(forKeys: [.nameKey, .fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
                    return FileItem(
                        url: url,
                        name: resourceValues?.name ?? url.lastPathComponent,
                        size: Int64(resourceValues?.fileSize ?? 0),
                        modified: resourceValues?.contentModificationDate ?? Date(),
                        isDirectory: resourceValues?.isDirectory ?? false,
                        icon: NSWorkspace.shared.icon(forFile: url.path)
                    )
                }
                .sorted(using: self.sortOrder)

                // Update UI on main thread
                DispatchQueue.main.async {
                    self.fileItems = items
                    self.appState.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.appState.error = error
                    self.fileItems = []
                    self.appState.isLoading = false
                }
            }
        }
    }
}