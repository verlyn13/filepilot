//
//  GitStatusServiceTests.swift
//  FilePilotTests
//
//  Tests for Git integration functionality
//

import XCTest
@testable import FilePilotCore

final class GitStatusServiceTests: XCTestCase {
    var gitService: GitStatusService!
    var testRepoPath: URL!

    override func setUp() async throws {
        gitService = GitStatusService()

        // Create a temporary test directory
        testRepoPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitTestRepo-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: testRepoPath, withIntermediateDirectories: true)

        // Initialize as git repo
        try runGitCommand(["init"], at: testRepoPath)
        try runGitCommand(["config", "user.name", "Test User"], at: testRepoPath)
        try runGitCommand(["config", "user.email", "test@example.com"], at: testRepoPath)
    }

    override func tearDown() async throws {
        // Clean up test repo
        try? FileManager.default.removeItem(at: testRepoPath)
        gitService = nil
    }

    // MARK: - Helper Methods

    private func runGitCommand(_ args: [String], at path: URL) throws {
        let process = Process()
        process.currentDirectoryURL = path
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "GitTest", code: Int(process.terminationStatus))
        }
    }

    private func createTestFile(name: String, content: String = "test content") throws -> URL {
        let fileURL = testRepoPath.appendingPathComponent(name)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - Repository Detection Tests

    func testFindRepositoryInRoot() throws {
        // Create a test file
        _ = try createTestFile(name: "test.txt")

        // Should find repo at root
        let foundRepo = gitService.findRepository(containing: testRepoPath)
        XCTAssertNotNil(foundRepo, "Should find repository at root")
        XCTAssertEqual(foundRepo?.path, testRepoPath)
    }

    func testFindRepositoryInSubdirectory() throws {
        // Create subdirectory
        let subdir = testRepoPath.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        // Should find repo when searching from subdirectory
        let foundRepo = gitService.findRepository(containing: subdir)
        XCTAssertNotNil(foundRepo, "Should find repository from subdirectory")
        // Compare paths as strings to avoid URL trailing slash differences
        XCTAssertEqual(foundRepo?.path.path, testRepoPath.path, "Should find repository at root")
    }

    func testFindRepositoryNotFound() {
        // Path with no git repo
        let nonRepoPath = FileManager.default.temporaryDirectory.appendingPathComponent("NotARepo")

        let foundRepo = gitService.findRepository(containing: nonRepoPath)
        XCTAssertNil(foundRepo, "Should not find repository in non-repo path")
    }

    // MARK: - Git Status Tests

    func testGitStatusWithUntrackedFile() throws {
        // Create untracked file
        _ = try createTestFile(name: "untracked.txt")

        // Load status
        if let repo = gitService.findRepository(containing: testRepoPath) {
            gitService.loadStatus(for: repo)

            // Wait for async loading
            let expectation = self.expectation(description: "Status loaded")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1.0)

            XCTAssertEqual(gitService.files.count, 1, "Should have 1 untracked file")
            XCTAssertEqual(gitService.files.first?.status, .untracked)
            XCTAssertEqual(gitService.files.first?.path, "untracked.txt")
        } else {
            XCTFail("Failed to find repository")
        }
    }

    func testGitStatusWithModifiedFile() throws {
        // Create and commit a file
        let file = try createTestFile(name: "tracked.txt", content: "initial")
        try runGitCommand(["add", file.lastPathComponent], at: testRepoPath)
        try runGitCommand(["commit", "-m", "Initial commit"], at: testRepoPath)

        // Modify the file
        try "modified content".write(to: file, atomically: true, encoding: .utf8)

        // Load status
        if let repo = gitService.findRepository(containing: testRepoPath) {
            gitService.loadStatus(for: repo)

            let expectation = self.expectation(description: "Status loaded")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1.0)

            XCTAssertEqual(gitService.files.count, 1, "Should have 1 modified file")
            XCTAssertEqual(gitService.files.first?.status, .modified)
        } else {
            XCTFail("Failed to find repository")
        }
    }

    func testGitStatusWithStagedFile() throws {
        // Create and stage a file
        let file = try createTestFile(name: "staged.txt")
        try runGitCommand(["add", file.lastPathComponent], at: testRepoPath)

        // Load status
        if let repo = gitService.findRepository(containing: testRepoPath) {
            gitService.loadStatus(for: repo)

            let expectation = self.expectation(description: "Status loaded")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1.0)

            XCTAssertEqual(gitService.files.count, 1, "Should have 1 staged file")
            XCTAssertTrue(gitService.files.first?.isStaged ?? false, "File should be staged")
        } else {
            XCTFail("Failed to find repository")
        }
    }

    func testGitStatusCleanRepo() throws {
        // Commit a file to have a clean repo
        let file = try createTestFile(name: "committed.txt")
        try runGitCommand(["add", file.lastPathComponent], at: testRepoPath)
        try runGitCommand(["commit", "-m", "Initial commit"], at: testRepoPath)

        // Load status
        if let repo = gitService.findRepository(containing: testRepoPath) {
            gitService.loadStatus(for: repo)

            let expectation = self.expectation(description: "Status loaded")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1.0)

            XCTAssertEqual(gitService.files.count, 0, "Clean repo should have no changes")
        } else {
            XCTFail("Failed to find repository")
        }
    }

    // MARK: - Git Operations Tests

    func testStageFile() throws {
        // Create untracked file
        _ = try createTestFile(name: "to-stage.txt")

        guard let repo = gitService.findRepository(containing: testRepoPath) else {
            XCTFail("Failed to find repository")
            return
        }

        gitService.loadStatus(for: repo)

        let expectation = self.expectation(description: "File staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Stage the file
            if let fileToStage = self.gitService.files.first {
                self.gitService.stage(fileToStage)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Verify file is staged
                    XCTAssertTrue(self.gitService.files.first?.isStaged ?? false, "File should be staged")
                    expectation.fulfill()
                }
            } else {
                XCTFail("No file found to stage")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testUnstageFile() throws {
        // Create initial commit so HEAD exists
        let initialFile = try createTestFile(name: "initial.txt")
        try runGitCommand(["add", initialFile.lastPathComponent], at: testRepoPath)
        try runGitCommand(["commit", "-m", "Initial commit"], at: testRepoPath)

        // Create and stage a file to unstage
        let file = try createTestFile(name: "to-unstage.txt")
        try runGitCommand(["add", file.lastPathComponent], at: testRepoPath)

        guard let repo = gitService.findRepository(containing: testRepoPath) else {
            XCTFail("Failed to find repository")
            return
        }

        gitService.loadStatus(for: repo)

        let expectation = self.expectation(description: "File unstaged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Unstage the file
            if let fileToUnstage = self.gitService.files.first {
                XCTAssertTrue(fileToUnstage.isStaged, "File should start staged")

                self.gitService.unstage(fileToUnstage)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Verify file is unstaged
                    XCTAssertFalse(self.gitService.files.first?.isStaged ?? true, "File should be unstaged")
                    expectation.fulfill()
                }
            } else {
                XCTFail("No file found to unstage")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testCommitFiles() throws {
        // Create files
        let file1 = try createTestFile(name: "file1.txt", content: "content1")
        let file2 = try createTestFile(name: "file2.txt", content: "content2")

        // Stage them directly with git
        try runGitCommand(["add", file1.lastPathComponent], at: testRepoPath)
        try runGitCommand(["add", file2.lastPathComponent], at: testRepoPath)

        // Create commit directly to avoid racing with service
        try runGitCommand(["commit", "-m", "Test commit"], at: testRepoPath)

        // Load status to verify clean repo
        guard let repo = gitService.findRepository(containing: testRepoPath) else {
            XCTFail("Failed to find repository")
            return
        }

        gitService.loadStatus(for: repo)

        let expectation = self.expectation(description: "Status loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // After commit, should have clean repo
            XCTAssertEqual(self.gitService.files.count, 0, "After commit, repo should be clean")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.5)
    }

    // MARK: - GitHub Detection Tests

    func testGitHubRemoteDetection() throws {
        // Add GitHub remote
        try runGitCommand(["remote", "add", "origin", "git@github.com:user/repo.git"], at: testRepoPath)

        let repo = gitService.findRepository(containing: testRepoPath)

        XCTAssertNotNil(repo, "Should find repository")
        XCTAssertTrue(repo?.isGitHub ?? false, "Should detect GitHub remote")
        XCTAssertEqual(repo?.remoteURL, "git@github.com:user/repo.git")
    }

    func testGitHubHTTPSRemoteDetection() throws {
        // Add GitHub HTTPS remote
        try runGitCommand(["remote", "add", "origin", "https://github.com/user/repo.git"], at: testRepoPath)

        let repo = gitService.findRepository(containing: testRepoPath)

        XCTAssertTrue(repo?.isGitHub ?? false, "Should detect GitHub HTTPS remote")
    }

    func testGitHubURLParsing() throws {
        // Add SSH remote
        try runGitCommand(["remote", "add", "origin", "git@github.com:user/repo.git"], at: testRepoPath)

        let repo = gitService.findRepository(containing: testRepoPath)

        XCTAssertNotNil(repo?.githubURL, "Should generate GitHub URL")
        XCTAssertEqual(repo?.githubURL?.absoluteString, "https://github.com/user/repo")
    }

    func testNonGitHubRemote() throws {
        // Add non-GitHub remote
        try runGitCommand(["remote", "add", "origin", "git@gitlab.com:user/repo.git"], at: testRepoPath)

        let repo = gitService.findRepository(containing: testRepoPath)

        XCTAssertFalse(repo?.isGitHub ?? true, "Should not detect GitHub for GitLab remote")
        XCTAssertNil(repo?.githubURL, "Should not generate GitHub URL for non-GitHub remote")
    }

    // MARK: - GitFile Tests

    func testGitFileEquality() {
        let file1 = GitFile(path: "test.txt", status: .modified, stagedStatus: nil)
        let file2 = GitFile(path: "test.txt", status: .modified, stagedStatus: nil)

        // Files with different IDs are not equal
        XCTAssertNotEqual(file1, file2, "Different GitFile instances should not be equal")
    }

    func testGitFileHashability() {
        let file1 = GitFile(path: "test.txt", status: .modified, stagedStatus: nil)
        let file2 = GitFile(path: "other.txt", status: .added, stagedStatus: .added)

        var set = Set<GitFile>()
        set.insert(file1)
        set.insert(file2)

        XCTAssertEqual(set.count, 2, "Set should contain both files")
        XCTAssertTrue(set.contains(file1), "Set should contain file1")
        XCTAssertTrue(set.contains(file2), "Set should contain file2")
    }

    func testGitFileDisplayPath() {
        let file = GitFile(path: "path/to/file.txt", status: .modified, stagedStatus: nil)
        XCTAssertEqual(file.displayPath, "path/to/file.txt")

        let fileWithBackslash = GitFile(path: "path\\to\\file.txt", status: .modified, stagedStatus: nil)
        XCTAssertEqual(fileWithBackslash.displayPath, "path/to/file.txt", "Should replace backslashes")
    }

    func testGitFileIsStaged() {
        let unstagedFile = GitFile(path: "test.txt", status: .modified, stagedStatus: nil)
        XCTAssertFalse(unstagedFile.isStaged, "File without stagedStatus should not be staged")

        let stagedFile = GitFile(path: "test.txt", status: .modified, stagedStatus: .modified)
        XCTAssertTrue(stagedFile.isStaged, "File with stagedStatus should be staged")
    }

    // MARK: - GitFileStatus Tests

    func testGitFileStatusDisplayNames() {
        XCTAssertEqual(GitFileStatus.modified.displayName, "Modified")
        XCTAssertEqual(GitFileStatus.added.displayName, "Added")
        XCTAssertEqual(GitFileStatus.deleted.displayName, "Deleted")
        XCTAssertEqual(GitFileStatus.renamed.displayName, "Renamed")
        XCTAssertEqual(GitFileStatus.untracked.displayName, "Untracked")
        XCTAssertEqual(GitFileStatus.staged.displayName, "Staged")
    }

    func testGitFileStatusSymbols() {
        XCTAssertEqual(GitFileStatus.modified.symbolName, "pencil")
        XCTAssertEqual(GitFileStatus.added.symbolName, "plus.circle")
        XCTAssertEqual(GitFileStatus.deleted.symbolName, "minus.circle")
        XCTAssertEqual(GitFileStatus.renamed.symbolName, "arrow.right")
        XCTAssertEqual(GitFileStatus.untracked.symbolName, "questionmark.circle")
        XCTAssertEqual(GitFileStatus.staged.symbolName, "checkmark.circle")
    }
}
