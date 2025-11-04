//
//  FileManager+Extensions.swift
//  FilePilot
//
//  FileManager extensions for enhanced file operations
//

import Foundation
import AppKit

extension FileManager {
    // MARK: - File Information

    func sizeOfFile(at url: URL) -> Int64? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }

    func formattedFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    func creationDate(for url: URL) -> Date? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.creationDate] as? Date
        } catch {
            return nil
        }
    }

    func modificationDate(for url: URL) -> Date? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    // MARK: - File Operations

    /// Safely moves an item to the Trash, preserving Finder's "Put Back" functionality
    /// - Parameter url: The URL of the item to trash
    /// - Returns: The URL of the trashed item (can be used for "Put Back")
    /// - Throws: If the operation fails
    @discardableResult
    func moveToTrash(_ url: URL) throws -> URL? {
        var trashedURL: NSURL?
        try trashItem(at: url, resultingItemURL: &trashedURL)

        // Record telemetry
        TelemetryService.shared.recordAction("file_trashed", metadata: [
            "path": url.path,
            "trashed_location": trashedURL?.path ?? "unknown"
        ])

        return trashedURL as URL?
    }

    /// Copies a file or directory to a new location
    /// - Parameters:
    ///   - sourceURL: The source file or directory
    ///   - destinationURL: The destination location
    ///   - overwrite: Whether to overwrite if destination exists
    /// - Throws: If the operation fails
    func copyItem(from sourceURL: URL, to destinationURL: URL, overwrite: Bool = false) throws {
        // Check if destination exists
        if fileExists(atPath: destinationURL.path) {
            if overwrite {
                try removeItem(at: destinationURL)
            } else {
                throw NSError(
                    domain: NSCocoaErrorDomain,
                    code: NSFileWriteFileExistsError,
                    userInfo: [NSLocalizedDescriptionKey: "File already exists at destination"]
                )
            }
        }

        try copyItem(at: sourceURL, to: destinationURL)

        // Record telemetry
        TelemetryService.shared.recordAction("file_copied", metadata: [
            "from": sourceURL.path,
            "to": destinationURL.path
        ])
    }

    /// Moves a file or directory to a new location
    /// - Parameters:
    ///   - sourceURL: The source file or directory
    ///   - destinationURL: The destination location
    ///   - overwrite: Whether to overwrite if destination exists
    /// - Throws: If the operation fails
    func moveItem(from sourceURL: URL, to destinationURL: URL, overwrite: Bool = false) throws {
        // Check if destination exists
        if fileExists(atPath: destinationURL.path) {
            if overwrite {
                try removeItem(at: destinationURL)
            } else {
                throw NSError(
                    domain: NSCocoaErrorDomain,
                    code: NSFileWriteFileExistsError,
                    userInfo: [NSLocalizedDescriptionKey: "File already exists at destination"]
                )
            }
        }

        try moveItem(at: sourceURL, to: destinationURL)

        // Record telemetry
        TelemetryService.shared.recordAction("file_moved", metadata: [
            "from": sourceURL.path,
            "to": destinationURL.path
        ])
    }

    /// Renames a file or directory
    /// - Parameters:
    ///   - url: The URL of the item to rename
    ///   - newName: The new name (without path)
    /// - Returns: The URL of the renamed item
    /// - Throws: If the operation fails
    @discardableResult
    func renameItem(at url: URL, to newName: String) throws -> URL {
        let parentURL = url.deletingLastPathComponent()
        let destinationURL = parentURL.appendingPathComponent(newName)

        try moveItem(at: url, to: destinationURL)

        // Record telemetry
        TelemetryService.shared.recordAction("file_renamed", metadata: [
            "old_name": url.lastPathComponent,
            "new_name": newName,
            "path": parentURL.path
        ])

        return destinationURL
    }

    /// Creates a new directory
    /// - Parameter url: The URL where to create the directory
    /// - Throws: If the operation fails
    func createDirectory(at url: URL) throws {
        try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

        // Record telemetry
        TelemetryService.shared.recordAction("directory_created", metadata: [
            "path": url.path
        ])
    }

    /// Generates a unique copy name for a file or directory
    ///
    /// This helper function creates numbered copy names following Finder's convention.
    /// Examples:
    /// - "document.txt" → "document copy.txt"
    /// - "document copy.txt" → "document copy 1.txt"
    /// - "folder" → "folder copy"
    ///
    /// - Parameters:
    ///   - url: The original file URL
    ///   - copyNumber: The copy iteration number (0 for first copy, 1 for second, etc.)
    /// - Returns: A unique name with "copy" suffix, preserving file extension
    /// - Note: Refactoring reduced duplicateItem complexity from 11 to 4
    private func generateCopyName(for url: URL, copyNumber: Int) -> String {
        let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let pathExtension = url.pathExtension
        let suffix = copyNumber == 0 ? " copy" : " copy \(copyNumber)"

        return pathExtension.isEmpty
            ? "\(nameWithoutExtension)\(suffix)"
            : "\(nameWithoutExtension)\(suffix).\(pathExtension)"
    }

    /// Duplicates a file or directory with automatic name generation
    ///
    /// Creates a copy in the same directory with "copy" appended to the name.
    /// Automatically finds a unique name if multiple copies exist.
    ///
    /// **Refactoring:** Complexity reduced from 11 to 4 by extracting `generateCopyName()`
    ///
    /// - Parameter url: The URL of the item to duplicate
    /// - Returns: The URL of the duplicated item
    /// - Throws: If the copy operation fails
    @discardableResult
    func duplicateItem(at url: URL) throws -> URL {
        let parentURL = url.deletingLastPathComponent()
        var copyNumber = 0
        var destinationURL: URL

        // Find available name (e.g., "file copy.txt", "file copy 2.txt", etc.)
        repeat {
            let newName = generateCopyName(for: url, copyNumber: copyNumber)
            destinationURL = parentURL.appendingPathComponent(newName)
            copyNumber += 1
        } while fileExists(atPath: destinationURL.path)

        try copyItem(at: url, to: destinationURL)

        // Record telemetry
        TelemetryService.shared.recordAction("file_duplicated", metadata: [
            "original": url.path,
            "duplicate": destinationURL.path
        ])

        return destinationURL
    }

    // MARK: - Batch Operations

    /// Moves multiple items to trash
    /// - Parameter urls: Array of URLs to trash
    /// - Returns: Array of URLs of trashed items (skips files that fail)
    /// - Note: This is fault-tolerant - continues with remaining files if one fails
    @discardableResult
    func moveToTrash(_ urls: [URL]) -> [URL] {
        var trashedURLs: [URL] = []

        for url in urls {
            guard let trashedURL = try? moveToTrash(url) else { continue }
            trashedURLs.append(trashedURL)
        }

        return trashedURLs
    }

    /// Gets the total size of multiple items
    /// - Parameter urls: Array of URLs
    /// - Returns: Total size in bytes
    func totalSize(of urls: [URL]) -> Int64 {
        urls.compactMap { sizeOfFile(at: $0) }.reduce(0, +)
    }
}