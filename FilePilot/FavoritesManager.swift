//
//  FavoritesManager.swift
//  FilePilot
//
//  Manages user's favorite paths with persistence and telemetry
//

import SwiftUI
import Foundation

/// Represents a favorite path with optional custom display name
struct FavoriteItem: Identifiable, Codable, Hashable {
    let id: UUID
    let url: URL
    var displayName: String?
    let dateAdded: Date

    init(url: URL, displayName: String? = nil) {
        self.id = UUID()
        self.url = url
        self.displayName = displayName
        self.dateAdded = Date()
    }

    /// The name to display in UI (custom name or last path component)
    var name: String {
        displayName ?? url.lastPathComponent
    }

    /// Icon name based on path type
    var iconName: String {
        // Check for special system directories
        let fileManager = FileManager.default
        if url == fileManager.homeDirectoryForCurrentUser {
            return "house.fill"
        } else if url.path.contains("/Desktop") {
            return "desktopcomputer"
        } else if url.path.contains("/Downloads") {
            return "arrow.down.circle.fill"
        } else if url.path.contains("/Documents") {
            return "doc.fill"
        } else if url.path.contains("/Applications") {
            return "app.fill"
        } else {
            // Check if it's a directory
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                return isDirectory.boolValue ? "folder.fill" : "doc.fill"
            }
            return "folder.fill"
        }
    }
}

/// Service for managing favorite paths with UserDefaults persistence
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    @Published private(set) var favorites: [FavoriteItem] = []

    private let userDefaultsKey = "FilePilot.Favorites"
    private let telemetry = TelemetryService.shared

    private init() {
        loadFavorites()
    }

    // MARK: - Public Interface

    /// Add a new favorite path
    /// - Parameters:
    ///   - url: The URL to add to favorites
    ///   - displayName: Optional custom display name
    /// - Returns: True if added successfully, false if already exists
    @discardableResult
    func addFavorite(url: URL, displayName: String? = nil) -> Bool {
        // Check if already exists
        if favorites.contains(where: { $0.url == url }) {
            telemetry.recordAction("favorite_add_duplicate", metadata: [
                "path": url.path
            ])
            return false
        }

        let favorite = FavoriteItem(url: url, displayName: displayName)
        favorites.append(favorite)
        saveFavorites()

        telemetry.recordAction("favorite_added", metadata: [
            "path": url.path,
            "hasCustomName": displayName != nil,
            "totalFavorites": favorites.count
        ])

        return true
    }

    /// Remove a favorite by ID
    /// - Parameter id: The UUID of the favorite to remove
    func removeFavorite(id: UUID) {
        guard let index = favorites.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = favorites.remove(at: index)
        saveFavorites()

        telemetry.recordAction("favorite_removed", metadata: [
            "path": removed.url.path,
            "totalFavorites": favorites.count
        ])
    }

    /// Remove a favorite by URL
    /// - Parameter url: The URL of the favorite to remove
    func removeFavorite(url: URL) {
        guard let favorite = favorites.first(where: { $0.url == url }) else {
            return
        }
        removeFavorite(id: favorite.id)
    }

    /// Update the display name of a favorite
    /// - Parameters:
    ///   - id: The UUID of the favorite to update
    ///   - displayName: New display name (nil to use default)
    func updateDisplayName(id: UUID, displayName: String?) {
        guard let index = favorites.firstIndex(where: { $0.id == id }) else {
            return
        }

        favorites[index].displayName = displayName
        saveFavorites()

        telemetry.recordAction("favorite_renamed", metadata: [
            "path": favorites[index].url.path,
            "hasCustomName": displayName != nil
        ])
    }

    /// Check if a URL is in favorites
    /// - Parameter url: The URL to check
    /// - Returns: True if the URL is favorited
    func isFavorite(url: URL) -> Bool {
        favorites.contains(where: { $0.url == url })
    }

    /// Reorder favorites
    /// - Parameters:
    ///   - source: Source indices
    ///   - destination: Destination index
    func moveFavorites(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
        saveFavorites()

        telemetry.recordAction("favorites_reordered", metadata: [
            "totalFavorites": favorites.count
        ])
    }

    /// Clear all favorites
    func clearAll() {
        let count = favorites.count
        favorites.removeAll()
        saveFavorites()

        telemetry.recordAction("favorites_cleared", metadata: [
            "clearedCount": count
        ])
    }

    // MARK: - Persistence

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            favorites = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([FavoriteItem].self, from: data)
            // Filter out favorites that point to non-existent paths
            favorites = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }

            // If we filtered any, save the cleaned list
            if decoded.count != favorites.count {
                saveFavorites()
                telemetry.recordAction("favorites_cleaned", metadata: [
                    "removed": decoded.count - favorites.count,
                    "remaining": favorites.count
                ])
            }

            telemetry.recordAction("favorites_loaded", metadata: [
                "count": favorites.count
            ])
        } catch {
            print("[FavoritesManager] Failed to decode favorites: \(error)")
            favorites = []

            telemetry.recordError(error, context: "favorites_load")
        }
    }

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)

            #if DEBUG
            print("[FavoritesManager] Saved \(favorites.count) favorites")
            #endif
        } catch {
            print("[FavoritesManager] Failed to encode favorites: \(error)")
            telemetry.recordError(error, context: "favorites_save")
        }
    }
}
