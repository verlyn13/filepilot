//
//  AppStateTests.swift
//  FilePilotTests
//
//  Test suite for AppState navigation and state management
//

import XCTest
import Combine
@testable import FilePilotCore

final class AppStateTests: XCTestCase {
    var appState: AppState!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        appState = AppState()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables.removeAll()
        appState = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(appState.currentPath, FileManager.default.homeDirectoryForCurrentUser, "Should start at home directory")
        XCTAssertTrue(appState.selectedItems.isEmpty, "Selected items should be empty initially")
        XCTAssertEqual(appState.viewMode, .list, "Should default to list view")
        XCTAssertFalse(appState.showHiddenFiles, "Hidden files should be hidden by default")
        XCTAssertFalse(appState.isLoading, "Should not be loading initially")
        XCTAssertNil(appState.error, "Should not have error initially")
    }

    func testGitRelatedInitialState() {
        XCTAssertFalse(appState.isGitRepository, "Should not be in git repo initially")
        XCTAssertFalse(appState.hasUnstagedChanges, "Should not have unstaged changes initially")
        XCTAssertFalse(appState.hasStagedChanges, "Should not have staged changes initially")
        XCTAssertFalse(appState.hasGitHubRemote, "Should not have GitHub remote initially")
        XCTAssertFalse(appState.showGoToPath, "Go to path dialog should be hidden initially")
        XCTAssertFalse(appState.showCommitDialog, "Commit dialog should be hidden initially")
    }

    // MARK: - Navigation Tests

    func testNavigateToHome() {
        // Change to a different path first
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        appState.currentPath = desktop

        // Navigate to home
        appState.navigateToHome()

        XCTAssertEqual(appState.currentPath, FileManager.default.homeDirectoryForCurrentUser, "Should navigate to home")
    }

    func testNavigateToDesktop() {
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            XCTFail("Desktop directory should be available")
            return
        }

        appState.navigateToDesktop()

        XCTAssertEqual(appState.currentPath, desktop, "Should navigate to desktop")
    }

    func testNavigateToDownloads() {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            XCTFail("Downloads directory should be available")
            return
        }

        appState.navigateToDownloads()

        XCTAssertEqual(appState.currentPath, downloads, "Should navigate to downloads")
    }

    func testNavigateToDocuments() {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Documents directory should be available")
            return
        }

        appState.navigateToDocuments()

        XCTAssertEqual(appState.currentPath, documents, "Should navigate to documents")
    }

    func testNavigateToCustomURL() {
        let tempDir = FileManager.default.temporaryDirectory
        appState.navigateTo(url: tempDir)

        XCTAssertEqual(appState.currentPath, tempDir, "Should navigate to custom URL")
    }

    // MARK: - Published Property Tests

    func testCurrentPathPublishing() {
        let expectation = XCTestExpectation(description: "Current path should publish changes")

        appState.$currentPath
            .dropFirst() // Skip initial value
            .sink { newPath in
                XCTAssertEqual(newPath, FileManager.default.temporaryDirectory)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        appState.currentPath = FileManager.default.temporaryDirectory

        wait(for: [expectation], timeout: 1.0)
    }

    func testViewModePublishing() {
        let expectation = XCTestExpectation(description: "View mode should publish changes")

        appState.$viewMode
            .dropFirst()
            .sink { newMode in
                XCTAssertEqual(newMode, .grid)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        appState.viewMode = .grid

        wait(for: [expectation], timeout: 1.0)
    }

    func testSelectedItemsPublishing() {
        let expectation = XCTestExpectation(description: "Selected items should publish changes")
        let testURL = URL(fileURLWithPath: "/tmp/test.txt")

        appState.$selectedItems
            .dropFirst()
            .sink { newSelection in
                XCTAssertEqual(newSelection.count, 1)
                XCTAssertTrue(newSelection.contains(testURL))
                expectation.fulfill()
            }
            .store(in: &cancellables)

        appState.selectedItems.insert(testURL)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - View Mode Tests

    func testViewModeChange() {
        XCTAssertEqual(appState.viewMode, .list, "Should start in list mode")

        appState.viewMode = .grid
        XCTAssertEqual(appState.viewMode, .grid, "Should change to grid mode")

        appState.viewMode = .column
        XCTAssertEqual(appState.viewMode, .column, "Should change to column mode")
    }

    func testAllViewModesAvailable() {
        let allModes = ViewMode.allCases
        XCTAssertEqual(allModes.count, 3, "Should have 3 view modes")
        XCTAssertTrue(allModes.contains(.list), "Should include list mode")
        XCTAssertTrue(allModes.contains(.grid), "Should include grid mode")
        XCTAssertTrue(allModes.contains(.column), "Should include column mode")
    }

    // MARK: - Hidden Files Tests

    func testToggleHiddenFiles() {
        XCTAssertFalse(appState.showHiddenFiles, "Should start with hidden files hidden")

        appState.toggleHiddenFiles()
        XCTAssertTrue(appState.showHiddenFiles, "Should show hidden files after toggle")

        appState.toggleHiddenFiles()
        XCTAssertFalse(appState.showHiddenFiles, "Should hide hidden files after second toggle")
    }

    // MARK: - Loading State Tests

    func testLoadingState() {
        XCTAssertFalse(appState.isLoading, "Should not be loading initially")

        appState.isLoading = true
        XCTAssertTrue(appState.isLoading, "Should be loading after setting to true")

        appState.isLoading = false
        XCTAssertFalse(appState.isLoading, "Should not be loading after setting to false")
    }

    // MARK: - Error State Tests

    func testErrorState() {
        XCTAssertNil(appState.error, "Should have no error initially")

        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        appState.error = testError

        XCTAssertNotNil(appState.error, "Should have error after setting")
        XCTAssertEqual((appState.error as NSError?)?.code, 1, "Error code should match")
    }

    // MARK: - Git-Related Tests

    func testGitRepositoryState() {
        XCTAssertFalse(appState.isGitRepository)

        appState.isGitRepository = true
        XCTAssertTrue(appState.isGitRepository, "Should mark as git repository")
    }

    func testGitChangesState() {
        XCTAssertFalse(appState.hasUnstagedChanges)
        XCTAssertFalse(appState.hasStagedChanges)

        appState.hasUnstagedChanges = true
        appState.hasStagedChanges = true

        XCTAssertTrue(appState.hasUnstagedChanges, "Should have unstaged changes")
        XCTAssertTrue(appState.hasStagedChanges, "Should have staged changes")
    }

    func testGitHubRemoteState() {
        XCTAssertFalse(appState.hasGitHubRemote)

        appState.hasGitHubRemote = true
        XCTAssertTrue(appState.hasGitHubRemote, "Should have GitHub remote")
    }

    func testShowGitStatus() {
        // This method just records telemetry, ensure it doesn't crash
        appState.showGitStatus()
        // No assertion needed - just verify no crash
    }

    func testStageChanges() {
        // This method just records telemetry, ensure it doesn't crash
        appState.stageChanges()
        // No assertion needed - just verify no crash
    }

    func testOpenOnGitHub() {
        // This method just records telemetry, ensure it doesn't crash
        appState.openOnGitHub()
        // No assertion needed - just verify no crash
    }

    // MARK: - Dialog State Tests

    func testGoToPathDialog() {
        XCTAssertFalse(appState.showGoToPath)

        appState.showGoToPath = true
        XCTAssertTrue(appState.showGoToPath, "Go to path dialog should be shown")

        appState.showGoToPath = false
        XCTAssertFalse(appState.showGoToPath, "Go to path dialog should be hidden")
    }

    func testCommitDialog() {
        XCTAssertFalse(appState.showCommitDialog)

        appState.showCommitDialog = true
        XCTAssertTrue(appState.showCommitDialog, "Commit dialog should be shown")

        appState.showCommitDialog = false
        XCTAssertFalse(appState.showCommitDialog, "Commit dialog should be hidden")
    }

    // MARK: - Window Management Tests

    func testOpenNewWindow() {
        // This method just records telemetry, ensure it doesn't crash
        appState.openNewWindow()
        // No assertion needed - just verify no crash
    }

    func testOpenNewTab() {
        // This method just records telemetry, ensure it doesn't crash
        appState.openNewTab()
        // No assertion needed - just verify no crash
    }

    // MARK: - Selection Tests

    func testSelectedItemsManipulation() {
        let url1 = URL(fileURLWithPath: "/tmp/file1.txt")
        let url2 = URL(fileURLWithPath: "/tmp/file2.txt")

        XCTAssertTrue(appState.selectedItems.isEmpty, "Should start with no selection")

        appState.selectedItems.insert(url1)
        XCTAssertEqual(appState.selectedItems.count, 1, "Should have 1 selected item")
        XCTAssertTrue(appState.selectedItems.contains(url1), "Should contain url1")

        appState.selectedItems.insert(url2)
        XCTAssertEqual(appState.selectedItems.count, 2, "Should have 2 selected items")
        XCTAssertTrue(appState.selectedItems.contains(url2), "Should contain url2")

        appState.selectedItems.remove(url1)
        XCTAssertEqual(appState.selectedItems.count, 1, "Should have 1 selected item after removal")
        XCTAssertFalse(appState.selectedItems.contains(url1), "Should not contain url1")

        appState.selectedItems.removeAll()
        XCTAssertTrue(appState.selectedItems.isEmpty, "Should have no selection after removeAll")
    }

    // MARK: - Multiple Property Change Tests

    func testMultiplePropertyChanges() {
        // Test that multiple properties can be changed independently
        appState.viewMode = .grid
        appState.showHiddenFiles = true
        appState.isLoading = true
        appState.currentPath = FileManager.default.temporaryDirectory

        XCTAssertEqual(appState.viewMode, .grid)
        XCTAssertTrue(appState.showHiddenFiles)
        XCTAssertTrue(appState.isLoading)
        XCTAssertEqual(appState.currentPath, FileManager.default.temporaryDirectory)
    }

    // MARK: - ObservableObject Conformance Tests

    func testObservableObjectConformance() {
        // Verify that AppState conforms to ObservableObject
        // AppState is a class that conforms to ObservableObject protocol
        XCTAssertNotNil(appState, "AppState should not be nil")
        // Verify @Published properties are observable
        XCTAssertNotNil(appState.objectWillChange, "AppState should have objectWillChange publisher")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentPropertyAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access should not crash")
        expectation.expectedFulfillmentCount = 10

        DispatchQueue.concurrentPerform(iterations: 10) { index in
            DispatchQueue.main.async {
                self.appState.viewMode = [.list, .grid, .column].randomElement()!
                self.appState.showHiddenFiles.toggle()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - ViewMode Tests

final class ViewModeTests: XCTestCase {
    func testViewModeRawValues() {
        XCTAssertEqual(ViewMode.list.rawValue, "List")
        XCTAssertEqual(ViewMode.grid.rawValue, "Grid")
        XCTAssertEqual(ViewMode.column.rawValue, "Column")
    }

    func testViewModeFromRawValue() {
        XCTAssertEqual(ViewMode(rawValue: "List"), .list)
        XCTAssertEqual(ViewMode(rawValue: "Grid"), .grid)
        XCTAssertEqual(ViewMode(rawValue: "Column"), .column)
        XCTAssertNil(ViewMode(rawValue: "Invalid"))
    }

    func testAllCases() {
        let allCases = ViewMode.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.list))
        XCTAssertTrue(allCases.contains(.grid))
        XCTAssertTrue(allCases.contains(.column))
    }
}
