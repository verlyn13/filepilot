//
//  FilterState.swift
//  FilePilot
//
//  Advanced filtering and search state management
//

import Foundation
import SwiftUI

/// File type categories for filtering
enum FileTypeFilter: String, CaseIterable, Identifiable {
    case all = "All Files"
    case documents = "Documents"
    case images = "Images"
    case videos = "Videos"
    case audio = "Audio"
    case code = "Code"
    case archives = "Archives"

    var id: String { rawValue }

    /// File extensions for this category
    var extensions: Set<String> {
        switch self {
        case .all:
            return []
        case .documents:
            return ["pdf", "doc", "docx", "txt", "rtf", "md", "pages"]
        case .images:
            return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "svg"]
        case .videos:
            return ["mp4", "mov", "avi", "mkv", "m4v", "wmv"]
        case .audio:
            return ["mp3", "m4a", "wav", "aac", "flac", "ogg"]
        case .code:
            return ["swift", "js", "ts", "py", "java", "cpp", "c", "h", "rs", "go"]
        case .archives:
            return ["zip", "tar", "gz", "rar", "7z", "dmg"]
        }
    }

    func matches(_ fileExtension: String) -> Bool {
        if self == .all { return true }
        return extensions.contains(fileExtension.lowercased())
    }
}

/// Size comparison operators
enum SizeComparison: String, CaseIterable {
    case greaterThan = "Greater than"
    case lessThan = "Less than"
    case between = "Between"

    func matches(size: Int64, min: Int64, max: Int64?) -> Bool {
        switch self {
        case .greaterThan:
            return size > min
        case .lessThan:
            return size < min
        case .between:
            guard let max = max else { return size > min }
            return size >= min && size <= max
        }
    }
}

/// Comprehensive filter state
class FilterState: ObservableObject {
    @Published var searchText: String = ""
    @Published var useRegex: Bool = false
    @Published var caseSensitive: Bool = false

    // Type filter
    @Published var fileType: FileTypeFilter = .all

    // Date filters
    @Published var dateFilterEnabled: Bool = false
    @Published var dateFrom: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var dateTo: Date = Date()

    // Size filters
    @Published var sizeFilterEnabled: Bool = false
    @Published var sizeComparison: SizeComparison = .greaterThan
    @Published var sizeMin: Int64 = 1024 * 1024 // 1 MB default
    @Published var sizeMax: Int64 = 1024 * 1024 * 100 // 100 MB default

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        fileType != .all ||
        dateFilterEnabled ||
        sizeFilterEnabled
    }

    /// Reset all filters to defaults
    func reset() {
        searchText = ""
        useRegex = false
        caseSensitive = false
        fileType = .all
        dateFilterEnabled = false
        sizeFilterEnabled = false
    }

    /// Apply all filters to a file item
    ///
    /// Directories are excluded when type or size filters are active
    func matches(_ item: FileItem) -> Bool {
        // Search text filter (applies to all items)
        if !searchText.isEmpty {
            if useRegex {
                guard let regex = try? NSRegularExpression(
                    pattern: searchText,
                    options: caseSensitive ? [] : .caseInsensitive
                ) else {
                    return false
                }
                let range = NSRange(item.name.startIndex..., in: item.name)
                if regex.firstMatch(in: item.name, range: range) == nil {
                    return false
                }
            } else {
                if caseSensitive {
                    if !item.name.contains(searchText) {
                        return false
                    }
                } else {
                    if !item.name.localizedCaseInsensitiveContains(searchText) {
                        return false
                    }
                }
            }
        }

        // Date filter (applies to all items)
        if dateFilterEnabled {
            if item.modified < dateFrom || item.modified > dateTo {
                return false
            }
        }

        // Handle directories
        if item.isDirectory {
            // Type filter excludes directories (only show matching file types)
            if fileType != .all {
                return false
            }
            // Size filter passes directories through (size doesn't apply to folders)
            // Search and date filters already applied above
            return true
        }

        // File type filter
        if fileType != .all {
            let ext = item.url.pathExtension
            if !fileType.matches(ext) {
                return false
            }
        }

        // Size filter
        if sizeFilterEnabled {
            if !sizeComparison.matches(size: item.size, min: sizeMin, max: sizeMax) {
                return false
            }
        }

        return true
    }
}

/// Saved search query
struct SavedSearch: Identifiable, Codable {
    let id: UUID
    let name: String
    let searchText: String
    let useRegex: Bool
    let fileType: String
    let dateFilterEnabled: Bool
    let sizeFilterEnabled: Bool

    init(id: UUID = UUID(), name: String, state: FilterState) {
        self.id = id
        self.name = name
        self.searchText = state.searchText
        self.useRegex = state.useRegex
        self.fileType = state.fileType.rawValue
        self.dateFilterEnabled = state.dateFilterEnabled
        self.sizeFilterEnabled = state.sizeFilterEnabled
    }

    func apply(to state: FilterState) {
        state.searchText = searchText
        state.useRegex = useRegex
        state.fileType = FileTypeFilter(rawValue: fileType) ?? .all
        state.dateFilterEnabled = dateFilterEnabled
        state.sizeFilterEnabled = sizeFilterEnabled
    }
}

/// Service for managing saved searches
class SavedSearchService: ObservableObject {
    static let shared = SavedSearchService()

    @Published var searches: [SavedSearch] = []

    private let userDefaultsKey = "com.filepilot.savedSearches"

    init() {
        loadSearches()
    }

    func save(_ search: SavedSearch) {
        searches.append(search)
        persistSearches()

        TelemetryService.shared.recordAction("search_saved", metadata: [
            "name": search.name,
            "uses_regex": search.useRegex
        ])
    }

    func delete(_ search: SavedSearch) {
        searches.removeAll { $0.id == search.id }
        persistSearches()

        TelemetryService.shared.recordAction("search_deleted", metadata: [
            "name": search.name
        ])
    }

    private func loadSearches() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([SavedSearch].self, from: data) else {
            return
        }
        searches = decoded
    }

    private func persistSearches() {
        guard let encoded = try? JSONEncoder().encode(searches) else { return }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
}
