//
//  GitStatusService.swift
//  FilePilot
//
//  Git repository detection and status tracking
//

import Foundation
import Combine

/// Git file status
enum GitFileStatus: String {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case untracked = "?"
    case staged = "S"

    var displayName: String {
        switch self {
        case .modified: return "Modified"
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .untracked: return "Untracked"
        case .staged: return "Staged"
        }
    }

    var symbolName: String {
        switch self {
        case .modified: return "pencil"
        case .added: return "plus.circle"
        case .deleted: return "minus.circle"
        case .renamed: return "arrow.right"
        case .untracked: return "questionmark.circle"
        case .staged: return "checkmark.circle"
        }
    }
}

/// Represents a file with git status
struct GitFile: Identifiable, Equatable, Hashable {
    let id = UUID()
    let path: String
    let status: GitFileStatus
    let stagedStatus: GitFileStatus?

    var displayPath: String {
        // Replace backslashes with forward slashes for display
        path.replacingOccurrences(of: "\\", with: "/")
    }

    var isStaged: Bool {
        stagedStatus != nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Git repository information
struct GitRepository: Identifiable, Equatable {
    let id = UUID()
    let path: URL
    let branch: String
    let remoteURL: String?
    let isGitHub: Bool

    var displayName: String {
        path.lastPathComponent
    }

    var githubURL: URL? {
        guard isGitHub,
              let remoteURL = remoteURL,
              let url = parseGitHubURL(from: remoteURL) else {
            return nil
        }
        return url
    }

    private func parseGitHubURL(from remote: String) -> URL? {
        // Parse git@github.com:user/repo.git or https://github.com/user/repo.git
        var urlString = remote

        // Convert SSH to HTTPS
        if urlString.hasPrefix("git@github.com:") {
            urlString = urlString.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
        }

        // Remove .git suffix
        if urlString.hasSuffix(".git") {
            urlString = String(urlString.dropLast(4))
        }

        return URL(string: urlString)
    }
}

/// Service for managing git operations
class GitStatusService: ObservableObject {
    static let shared = GitStatusService()

    @Published var repositories: [GitRepository] = []
    @Published var currentRepository: GitRepository?
    @Published var files: [GitFile] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var cancellables = Set<AnyCancellable>()

    init() {
        discoverRepositories()
    }

    // MARK: - Repository Discovery

    /// Scan common locations for git repositories
    func discoverRepositories() {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser

        let searchPaths = [
            home.appendingPathComponent("Development"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Documents/GitHub"),
            home.appendingPathComponent("Documents/Projects")
        ]

        var found: [GitRepository] = []

        for path in searchPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            found.append(contentsOf: findGitRepos(in: path))
        }

        DispatchQueue.main.async {
            self.repositories = found
            TelemetryService.shared.recordAction("git_repos_discovered", metadata: [
                "count": found.count
            ])
        }
    }

    /// Find git repositories in directory (searches 2 levels deep)
    private func findGitRepos(in directory: URL, depth: Int = 0) -> [GitRepository] {
        let fileManager = FileManager.default
        var repos: [GitRepository] = []

        // Limit recursion to 2 levels to avoid performance issues
        guard depth < 2 else { return repos }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return repos
        }

        for item in contents {
            // Check if this directory contains a .git folder
            let gitPath = item.appendingPathComponent(".git")
            if fileManager.fileExists(atPath: gitPath.path) {
                if let repo = loadRepository(at: item) {
                    repos.append(repo)
                }
            } else if depth < 1 {
                // Search one level deeper for nested repos (e.g., ~/Development/personal/myfiles)
                let values = try? item.resourceValues(forKeys: [.isDirectoryKey])
                if values?.isDirectory == true {
                    repos.append(contentsOf: findGitRepos(in: item, depth: depth + 1))
                }
            }
        }

        return repos
    }

    /// Check if a path is within a git repository
    func findRepository(containing path: URL) -> GitRepository? {
        var currentPath = path
        let fileManager = FileManager.default

        // Walk up the directory tree looking for .git
        while currentPath.path != "/" {
            let gitPath = currentPath.appendingPathComponent(".git")
            if fileManager.fileExists(atPath: gitPath.path) {
                return loadRepository(at: currentPath)
            }
            currentPath = currentPath.deletingLastPathComponent()
        }

        return nil
    }

    /// Load repository information
    private func loadRepository(at path: URL) -> GitRepository? {
        guard let branch = getCurrentBranch(at: path) else {
            return nil
        }

        // Remote URL is optional - local repos may not have remotes
        let remoteURL = getRemoteURL(at: path)
        let isGitHub = remoteURL?.contains("github.com") ?? false

        return GitRepository(
            path: path,
            branch: branch,
            remoteURL: remoteURL,
            isGitHub: isGitHub
        )
    }

    // MARK: - Git Status

    /// Load git status for the current repository
    func loadStatus(for repository: GitRepository) {
        isLoading = true
        error = nil
        currentRepository = repository

        DispatchQueue.global(qos: .userInitiated).async {
            let files = self.getGitStatus(at: repository.path)

            DispatchQueue.main.async {
                self.files = files
                self.isLoading = false

                TelemetryService.shared.recordAction("git_status_loaded", metadata: [
                    "repo": repository.displayName,
                    "file_count": files.count
                ])
            }
        }
    }

    /// Get git status output
    private func getGitStatus(at path: URL) -> [GitFile] {
        let process = Process()
        process.currentDirectoryURL = path
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["status", "--porcelain"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return []
            }

            return parseGitStatus(output)
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
            return []
        }
    }

    /// Parse git status --porcelain output
    private func parseGitStatus(_ output: String) -> [GitFile] {
        var files: [GitFile] = []

        for line in output.components(separatedBy: .newlines) {
            guard !line.isEmpty else { continue }
            guard line.count >= 4 else { continue }

            let statusChars = line.prefix(2)
            let filePath = String(line.dropFirst(3))

            let staged = statusChars.first.flatMap { char -> GitFileStatus? in
                switch char {
                case "M": return .modified
                case "A": return .added
                case "D": return .deleted
                case "R": return .renamed
                case " ": return nil
                default: return nil
                }
            }

            let unstaged = statusChars.last.flatMap { char -> GitFileStatus? in
                switch char {
                case "M": return .modified
                case "D": return .deleted
                case "?": return .untracked
                case " ": return nil
                default: return nil
                }
            }

            let status = unstaged ?? staged ?? .modified

            files.append(GitFile(
                path: filePath,
                status: status,
                stagedStatus: staged
            ))
        }

        return files
    }

    // MARK: - Git Commands

    /// Get current branch name
    private func getCurrentBranch(at path: URL) -> String? {
        let process = Process()
        process.currentDirectoryURL = path
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["branch", "--show-current"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    /// Get remote URL
    private func getRemoteURL(at path: URL) -> String? {
        let process = Process()
        process.currentDirectoryURL = path
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["remote", "get-url", "origin"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    /// Stage a file
    func stage(_ file: GitFile) {
        guard let repo = currentRepository else { return }

        let process = Process()
        process.currentDirectoryURL = repo.path
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["add", file.path]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                loadStatus(for: repo)

                TelemetryService.shared.recordAction("git_file_staged", metadata: [
                    "file": file.path
                ])
            }
        } catch {
            self.error = error
        }
    }

    /// Unstage a file
    func unstage(_ file: GitFile) {
        guard let repo = currentRepository else { return }

        let process = Process()
        process.currentDirectoryURL = repo.path
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["reset", "HEAD", file.path]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                loadStatus(for: repo)

                TelemetryService.shared.recordAction("git_file_unstaged", metadata: [
                    "file": file.path
                ])
            }
        } catch {
            self.error = error
        }
    }

    /// Create a commit
    func commit(message: String, files: [GitFile]) -> Bool {
        guard let repo = currentRepository else { return false }

        // Stage selected files
        for file in files {
            stage(file)
        }

        // Create commit
        let process = Process()
        process.currentDirectoryURL = repo.path
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["commit", "-m", message]

        do {
            try process.run()
            process.waitUntilExit()

            let success = process.terminationStatus == 0

            if success {
                loadStatus(for: repo)

                TelemetryService.shared.recordAction("git_commit_created", metadata: [
                    "repo": repo.displayName,
                    "file_count": files.count
                ])
            }

            return success
        } catch {
            self.error = error
            return false
        }
    }
}
