//
//  CommitDialogView.swift
//  FilePilot
//
//  Git commit dialog UI
//

import SwiftUI

struct CommitDialogView: View {
    let files: [GitFile]
    let onCommit: (String) -> Bool

    @State private var commitMessage = ""
    @State private var isCommitting = false
    @State private var commitError: String?
    @Environment(\.dismiss) private var dismiss

    private let placeholderText = "Enter commit message...\n\nDescribe your changes clearly and concisely."

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Commit Changes")
                        .font(.headline)
                    Text("\(files.count) file\(files.count == 1 ? "" : "s") staged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Commit message editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Commit Message")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ZStack(alignment: .topLeading) {
                    if commitMessage.isEmpty {
                        Text(placeholderText)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $commitMessage)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .border(Color.secondary.opacity(0.2), width: 1)
                }

                // Message tips
                HStack(spacing: 16) {
                    Label("⌘↩ to commit", systemImage: "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .labelStyle(.titleOnly)

                    if commitMessage.count > 72 {
                        Text("⚠ First line should be ≤72 chars")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()

            Divider()

            // Files to be committed
            VStack(alignment: .leading, spacing: 8) {
                Text("Files to Commit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(files) { file in
                            HStack(spacing: 8) {
                                Image(systemName: file.status.symbolName)
                                    .foregroundColor(statusColor(for: file.status))
                                    .frame(width: 16)

                                Text(file.displayPath)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding(.horizontal)
            }
            .padding(.vertical)

            // Error message
            if let error = commitError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            // Action buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Commit") {
                    performCommit()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCommitting)
            }
            .padding()
        }
        .frame(width: 500, height: 550)
        .onAppear {
            // Generate suggested commit message based on files
            if commitMessage.isEmpty {
                commitMessage = generateSuggestedMessage()
            }
        }
    }

    // MARK: - Actions

    private func performCommit() {
        commitError = nil

        let message = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !message.isEmpty else {
            commitError = "Commit message cannot be empty"
            return
        }

        isCommitting = true

        DispatchQueue.global(qos: .userInitiated).async {
            let success = onCommit(message)

            DispatchQueue.main.async {
                isCommitting = false

                if success {
                    dismiss()
                } else {
                    commitError = "Failed to create commit. Check that files are properly staged."
                }
            }
        }
    }

    private func generateSuggestedMessage() -> String {
        // Generate a suggested message based on file changes
        let modified = files.filter { $0.status == .modified }.count
        let added = files.filter { $0.status == .added }.count
        let deleted = files.filter { $0.status == .deleted }.count

        var parts: [String] = []

        if added > 0 {
            parts.append("Add \(added) file\(added == 1 ? "" : "s")")
        }
        if modified > 0 {
            parts.append("Update \(modified) file\(modified == 1 ? "" : "s")")
        }
        if deleted > 0 {
            parts.append("Delete \(deleted) file\(deleted == 1 ? "" : "s")")
        }

        if parts.isEmpty {
            return "Update files"
        }

        return parts.joined(separator: ", ")
    }

    private func statusColor(for status: GitFileStatus) -> Color {
        switch status {
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

// MARK: - Preview

#Preview {
    CommitDialogView(
        files: [
            GitFile(path: "src/main.swift", status: .modified, stagedStatus: .modified),
            GitFile(path: "src/utils.swift", status: .added, stagedStatus: .added),
            GitFile(path: "README.md", status: .modified, stagedStatus: .modified)
        ],
        onCommit: { message in
            print("Committing with message: \(message)")
            return true
        }
    )
}
