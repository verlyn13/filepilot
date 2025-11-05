//
//  FilterStateTests.swift
//  FilePilotTests
//
//  Tests for advanced search and filtering functionality
//

import XCTest
@testable import FilePilot

final class FilterStateTests: XCTestCase {
    var filterState: FilterState!
    var testItems: [FileItem]!

    override func setUp() async throws {
        filterState = FilterState()

        // Create test file items
        testItems = [
            FileItem(
                url: URL(fileURLWithPath: "/test/document.pdf"),
                name: "document.pdf",
                size: 2 * 1024 * 1024, // 2 MB
                modified: Date().addingTimeInterval(-86400 * 7), // 1 week ago
                isDirectory: false,
                icon: nil
            ),
            FileItem(
                url: URL(fileURLWithPath: "/test/image.jpg"),
                name: "image.jpg",
                size: 500 * 1024, // 500 KB
                modified: Date().addingTimeInterval(-86400), // 1 day ago
                isDirectory: false,
                icon: nil
            ),
            FileItem(
                url: URL(fileURLWithPath: "/test/code.swift"),
                name: "code.swift",
                size: 10 * 1024, // 10 KB
                modified: Date(), // Now
                isDirectory: false,
                icon: nil
            ),
            FileItem(
                url: URL(fileURLWithPath: "/test/folder"),
                name: "folder",
                size: 0,
                modified: Date(),
                isDirectory: true,
                icon: nil
            )
        ]
    }

    // MARK: - Basic Search Tests

    func testEmptySearch() {
        filterState.searchText = ""
        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 4, "Empty search should return all items")
    }

    func testCaseInsensitiveSearch() {
        filterState.searchText = "CODE"
        filterState.caseSensitive = false

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find 'code.swift'")
        XCTAssertEqual(filtered.first?.name, "code.swift")
    }

    func testCaseSensitiveSearch() {
        filterState.searchText = "CODE"
        filterState.caseSensitive = true

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 0, "Should not find anything with case sensitive search")
    }

    func testPartialMatch() {
        filterState.searchText = "doc"

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find 'document.pdf'")
    }

    // MARK: - Regex Search Tests

    func testRegexSearch() {
        filterState.searchText = ".*\\.swift$"
        filterState.useRegex = true

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find .swift files")
        XCTAssertEqual(filtered.first?.name, "code.swift")
    }

    func testRegexWithCaseInsensitive() {
        filterState.searchText = "IMAGE"
        filterState.useRegex = true
        filterState.caseSensitive = false

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find 'image.jpg'")
    }

    func testInvalidRegex() {
        filterState.searchText = "["  // Invalid regex
        filterState.useRegex = true

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 0, "Invalid regex should match nothing")
    }

    // MARK: - File Type Filter Tests

    func testFileTypeFilterAll() {
        filterState.fileType = .all
        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 4, "Should return all items")
    }

    func testFileTypeFilterDocuments() {
        filterState.fileType = .documents
        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find PDF")
        XCTAssertTrue(filtered.contains(where: { $0.name == "document.pdf" }))
    }

    func testFileTypeFilterImages() {
        filterState.fileType = .images
        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find JPG")
        XCTAssertTrue(filtered.contains(where: { $0.name == "image.jpg" }))
    }

    func testFileTypeFilterCode() {
        filterState.fileType = .code
        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find Swift file")
        XCTAssertTrue(filtered.contains(where: { $0.name == "code.swift" }))
    }

    func testFileTypeFilterIgnoresDirectories() {
        filterState.fileType = .documents
        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertFalse(filtered.contains(where: { $0.isDirectory }), "Should not filter directories")
    }

    // MARK: - Date Filter Tests

    func testDateFilterDisabled() {
        filterState.dateFilterEnabled = false
        filterState.dateFrom = Date().addingTimeInterval(-86400) // 1 day ago
        filterState.dateTo = Date()

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 4, "Disabled date filter should return all")
    }

    func testDateFilterRecentFiles() {
        filterState.dateFilterEnabled = true
        filterState.dateFrom = Date().addingTimeInterval(-86400 * 2) // 2 days ago
        filterState.dateTo = Date()

        let filtered = testItems.filter { filterState.matches($0) }
        // Includes image.jpg, code.swift, and folder (all modified within last 2 days)
        XCTAssertEqual(filtered.count, 3, "Should find files and folders from last 2 days")
    }

    func testDateFilterExactRange() {
        filterState.dateFilterEnabled = true
        filterState.dateFrom = Date().addingTimeInterval(-86400 * 8) // 8 days ago
        filterState.dateTo = Date().addingTimeInterval(-86400 * 6) // 6 days ago

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find document from 7 days ago")
    }

    // MARK: - Size Filter Tests

    func testSizeFilterDisabled() {
        filterState.sizeFilterEnabled = false
        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 4, "Disabled size filter should return all")
    }

    func testSizeFilterGreaterThan() {
        filterState.sizeFilterEnabled = true
        filterState.sizeComparison = .greaterThan
        filterState.sizeMin = 1024 * 1024 // 1 MB

        let filtered = testItems.filter { filterState.matches($0) }
        // Includes document.pdf (>1MB) and folder (directories pass through)
        XCTAssertEqual(filtered.count, 2, "Should find files > 1MB plus directories")
        XCTAssertTrue(filtered.contains(where: { $0.name == "document.pdf" }))
        XCTAssertTrue(filtered.contains(where: { $0.isDirectory }))
    }

    func testSizeFilterLessThan() {
        filterState.sizeFilterEnabled = true
        filterState.sizeComparison = .lessThan
        filterState.sizeMin = 100 * 1024 // 100 KB

        let filtered = testItems.filter { filterState.matches($0) }
        // Includes code.swift (<100KB) and folder (directories pass through)
        XCTAssertEqual(filtered.count, 2, "Should find files < 100KB plus directories")
        XCTAssertTrue(filtered.contains(where: { $0.name == "code.swift" }))
        XCTAssertTrue(filtered.contains(where: { $0.isDirectory }))
    }

    func testSizeFilterBetween() {
        filterState.sizeFilterEnabled = true
        filterState.sizeComparison = .between
        filterState.sizeMin = 100 * 1024 // 100 KB
        filterState.sizeMax = 1024 * 1024 // 1 MB

        let filtered = testItems.filter { filterState.matches($0) }
        // Includes image.jpg (between 100KB-1MB) and folder (directories pass through)
        XCTAssertEqual(filtered.count, 2, "Should find files between 100KB and 1MB plus directories")
        XCTAssertTrue(filtered.contains(where: { $0.name == "image.jpg" }))
        XCTAssertTrue(filtered.contains(where: { $0.isDirectory }))
    }

    func testSizeFilterIgnoresDirectories() {
        filterState.sizeFilterEnabled = true
        filterState.sizeComparison = .greaterThan
        filterState.sizeMin = 0

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertTrue(filtered.contains(where: { $0.isDirectory }), "Directories should pass size filter")
    }

    // MARK: - Combined Filter Tests

    func testCombinedSearchAndType() {
        filterState.searchText = "doc"
        filterState.fileType = .documents

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find document.pdf")
    }

    func testCombinedAllFilters() {
        filterState.searchText = "image"
        filterState.fileType = .images
        filterState.dateFilterEnabled = true
        filterState.dateFrom = Date().addingTimeInterval(-86400 * 2)
        filterState.dateTo = Date()
        filterState.sizeFilterEnabled = true
        filterState.sizeComparison = .greaterThan
        filterState.sizeMin = 100 * 1024

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 1, "Should find image.jpg with all filters")
    }

    func testCombinedFiltersMismatch() {
        filterState.searchText = "code"
        filterState.fileType = .images // Wrong type

        let filtered = testItems.filter { filterState.matches($0) }
        XCTAssertEqual(filtered.count, 0, "Conflicting filters should match nothing")
    }

    // MARK: - State Management Tests

    func testHasActiveFilters() {
        XCTAssertFalse(filterState.hasActiveFilters, "New filter state should have no active filters")

        filterState.searchText = "test"
        XCTAssertTrue(filterState.hasActiveFilters, "Search text should activate filters")

        filterState.searchText = ""
        filterState.fileType = .documents
        XCTAssertTrue(filterState.hasActiveFilters, "File type should activate filters")

        filterState.fileType = .all
        filterState.dateFilterEnabled = true
        XCTAssertTrue(filterState.hasActiveFilters, "Date filter should activate filters")
    }

    func testReset() {
        filterState.searchText = "test"
        filterState.useRegex = true
        filterState.fileType = .documents
        filterState.dateFilterEnabled = true
        filterState.sizeFilterEnabled = true

        filterState.reset()

        XCTAssertTrue(filterState.searchText.isEmpty)
        XCTAssertFalse(filterState.useRegex)
        XCTAssertEqual(filterState.fileType, .all)
        XCTAssertFalse(filterState.dateFilterEnabled)
        XCTAssertFalse(filterState.sizeFilterEnabled)
    }

    // MARK: - Saved Search Tests

    func testSavedSearchCreation() {
        filterState.searchText = "test"
        filterState.useRegex = true
        filterState.fileType = .documents

        let saved = SavedSearch(name: "Test Search", state: filterState)

        XCTAssertEqual(saved.name, "Test Search")
        XCTAssertEqual(saved.searchText, "test")
        XCTAssertTrue(saved.useRegex)
        XCTAssertEqual(saved.fileType, "Documents")
    }

    func testSavedSearchApply() {
        let saved = SavedSearch(id: UUID(), name: "Test", state: filterState)

        let newState = FilterState()
        newState.searchText = "different"
        newState.useRegex = true

        saved.apply(to: newState)

        XCTAssertEqual(newState.searchText, filterState.searchText)
        XCTAssertEqual(newState.useRegex, filterState.useRegex)
    }
}
