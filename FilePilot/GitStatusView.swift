//
//  GitStatusView.swift
//  FilePilot
//
//  Git status display and management UI
//

import SwiftUI

struct GitStatusView: View {
    @ObservedObject var gitService = GitStatusService.shared
    @State private var showingCommitDialog = false
    @State private var selectedFiles: Set<GitFile> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Error display
            if let error = gitService.error {
                errorView(error: error)
                Divider()
            }

            if gitService.isLoading {
                loadingView
            } else if let repo = gitService.currentRepository {
                contentView(repo: repo)
            } else {
                emptyStateView
            }
        }
        .sheet(isPresented: $showingCommitDialog) {
            CommitDialogView(
                files: Array(selectedFiles),
                onCommit: { message in
                    let success = gitService.commit(message: message, files: Array(selectedFiles))
                    if success {
                        selectedFiles.removeAll()
                    }
                    return success
                }
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "arrow.triangle.branch")
                .foregroundColor(.accentColor)

            if let repo = gitService.currentRepository {
                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.displayName)
                        .font(.headline)
                    Text(repo.branch)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if repo.isGitHub, let githubURL = repo.githubURL {
                    Button(action: {
                        NSWorkspace.shared.open(githubURL)
                        TelemetryService.shared.recordAction("github_repo_opened", metadata: [
                            "repo": repo.displayName
                        ])
                    }) {
                        Label("GitHub", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderless)
                }

                Button(action: {
                    if let repo = gitService.currentRepository {
                        gitService.loadStatus(for: repo)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh status")
            } else {
                Text("Git Status")
                    .font(.headline)

                Spacer()
            }
        }
        .padding()
    }

    // MARK: - Content Views

    private func contentView(repo: GitRepository) -> some View {
        VStack(spacing: 0) {
            if gitService.files.isEmpty {
                ContentUnavailableView(
                    "No Changes",
                    systemImage: "checkmark.circle",
                    description: Text("Working directory clean")
                )
            } else {
                VStack(spacing: 0) {
                    // Action bar
                    actionBar

                    Divider()

                    // File list
                    fileList
                }
            }
        }
    }

    private var actionBar: some View {
        HStack {
            Text("\(gitService.files.count) changes")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if !selectedFiles.isEmpty {
                Button("Stage Selected (\(selectedFiles.count))") {
                    for file in selectedFiles {
                        gitService.stage(file)
                    }
                    selectedFiles.removeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Button("Commit...") {
                // Auto-select staged files
                selectedFiles = Set(gitService.files.filter { $0.isStaged })
                showingCommitDialog = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(gitService.files.filter { $0.isStaged }.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var fileList: some View {
        List(selection: $selectedFiles) {
            ForEach(gitService.files) { file in
                GitFileRow(file: file, onStage: {
                    gitService.stage(file)
                }, onUnstage: {
                    gitService.unstage(file)
                })
                .tag(file)
            }
        }
        .listStyle(.inset)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading git status...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Repository",
            systemImage: "folder",
            description: Text("Navigate to a git repository to see status")
        )
    }

    private func errorView(error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(error.localizedDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                gitService.error = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Dismiss error")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }
}

// MARK: - Git File Row

struct GitFileRow: View {
    let file: GitFile
    let onStage: () -> Void
    let onUnstage: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator (LEFT SIDE)
            Image(systemName: file.status.symbolName)
                .foregroundColor(statusColor)
                .frame(width: 20)

            // File path (MIDDLE)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayPath)
                    .lineLimit(1)

                Text(file.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 20)

            // Action button (RIGHT SIDE) - Always visible with different styles
            Group {
                if file.isStaged {
                    // STAGED: Show minus to unstage
                    Button(action: onUnstage) {
                        HStack(spacing: 4) {
                            Image(systemName: "minus.circle.fill")
                            Text("Unstage")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Unstage file")
                } else {
                    // UNSTAGED: Show plus to stage
                    Button(action: onStage) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Stage")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .help(file.status == .untracked ? "Add file" : "Stage changes")
                }
            }
            .fixedSize()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    private var statusColor: Color {
        switch file.status {
        case .modified:
            return .orange
        case .added:
            return .green
        case .deleted:
            return .red
        case .renamed:
            return .blue
        case .untracked:
            return .gray
        case .staged:
            return .green
        }
    }
}

// MARK: - Repository Selector

struct RepositorySelectorView: View {
    @ObservedObject var gitService: GitStatusService
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if gitService.repositories.isEmpty {
                VStack(spacing: 8) {
                    Text("No repositories found")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Scan Now") {
                        gitService.discoverRepositories()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            } else {
                ForEach(gitService.repositories, id: \.path) { repo in
                    Button(action: {
                        // Navigate to repo directory
                        appState.navigateTo(url: repo.path)
                        // Load git status
                        gitService.loadStatus(for: repo)
                    }) {
                        HStack {
                            Image(systemName: "folder.badge.gearshape")
                                .foregroundColor(.secondary)
                            Text(repo.displayName)
                                .font(.body)
                            Spacer()
                            Text(repo.branch)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if repo.isGitHub {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(
                        gitService.currentRepository?.path == repo.path ?
                        Color.accentColor.opacity(0.1) : Color.clear
                    )
                    .cornerRadius(6)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GitStatusView()
        .frame(width: 300, height: 400)
}
