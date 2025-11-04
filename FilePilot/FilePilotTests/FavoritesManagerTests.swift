//
//  FavoritesManagerTests.swift
//  FilePilotTests
//
//  Test suite for FavoritesManager
//

import XCTest
@testable import FilePilot

final class FavoritesManagerTests: XCTestCase {
    var favoritesManager: FavoritesManager!
    let testUserDefaultsKey = "FilePilot.Favorites"

    override func setUp() {
        super.setUp()
        favoritesManager = FavoritesManager.shared
        // Clear favorites before each test
        UserDefaults.standard.removeObject(forKey: testUserDefaultsKey)
        favoritesManager.clearAll()
    }

    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: testUserDefaultsKey)
        favoritesManager.clearAll()
        favoritesManager = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSingletonInstance() {
        let instance1 = FavoritesManager.shared
        let instance2 = FavoritesManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return same singleton instance")
    }

    // MARK: - Add Favorite Tests

    func testAddFavorite() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        let result = favoritesManager.addFavorite(url: testURL)

        XCTAssertTrue(result, "Should successfully add favorite")
        XCTAssertEqual(favoritesManager.favorites.count, 1, "Should have 1 favorite")
        XCTAssertEqual(favoritesManager.favorites.first?.url, testURL, "URL should match")
    }

    func testAddFavoriteWithCustomName() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        let customName = "My Home"
        let result = favoritesManager.addFavorite(url: testURL, displayName: customName)

        XCTAssertTrue(result, "Should successfully add favorite")
        XCTAssertEqual(favoritesManager.favorites.first?.displayName, customName, "Custom name should be set")
        XCTAssertEqual(favoritesManager.favorites.first?.name, customName, "Display name should return custom name")
    }

    func testAddDuplicateFavorite() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser

        let result1 = favoritesManager.addFavorite(url: testURL)
        XCTAssertTrue(result1, "First add should succeed")

        let result2 = favoritesManager.addFavorite(url: testURL)
        XCTAssertFalse(result2, "Duplicate add should fail")
        XCTAssertEqual(favoritesManager.favorites.count, 1, "Should still have only 1 favorite")
    }

    func testAddMultipleFavorites() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        favoritesManager.addFavorite(url: home)
        favoritesManager.addFavorite(url: desktop)
        favoritesManager.addFavorite(url: documents)

        XCTAssertEqual(favoritesManager.favorites.count, 3, "Should have 3 favorites")
    }

    // MARK: - Remove Favorite Tests

    func testRemoveFavoriteById() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        favoritesManager.addFavorite(url: testURL)

        guard let favoriteId = favoritesManager.favorites.first?.id else {
            XCTFail("Should have a favorite")
            return
        }

        favoritesManager.removeFavorite(id: favoriteId)
        XCTAssertEqual(favoritesManager.favorites.count, 0, "Should have no favorites after removal")
    }

    func testRemoveFavoriteByURL() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        favoritesManager.addFavorite(url: testURL)

        favoritesManager.removeFavorite(url: testURL)
        XCTAssertEqual(favoritesManager.favorites.count, 0, "Should have no favorites after removal")
    }

    func testRemoveNonExistentFavorite() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        favoritesManager.addFavorite(url: testURL)

        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path")
        favoritesManager.removeFavorite(url: nonExistentURL)

        XCTAssertEqual(favoritesManager.favorites.count, 1, "Should still have 1 favorite")
    }

    // MARK: - Update Tests

    func testUpdateDisplayName() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        favoritesManager.addFavorite(url: testURL)

        guard let favoriteId = favoritesManager.favorites.first?.id else {
            XCTFail("Should have a favorite")
            return
        }

        let newName = "Updated Name"
        favoritesManager.updateDisplayName(id: favoriteId, displayName: newName)

        XCTAssertEqual(favoritesManager.favorites.first?.displayName, newName, "Display name should be updated")
        XCTAssertEqual(favoritesManager.favorites.first?.name, newName, "Name should return updated display name")
    }

    func testUpdateDisplayNameToNil() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        favoritesManager.addFavorite(url: testURL, displayName: "Custom Name")

        guard let favoriteId = favoritesManager.favorites.first?.id else {
            XCTFail("Should have a favorite")
            return
        }

        favoritesManager.updateDisplayName(id: favoriteId, displayName: nil)

        XCTAssertNil(favoritesManager.favorites.first?.displayName, "Display name should be nil")
        XCTAssertEqual(favoritesManager.favorites.first?.name, testURL.lastPathComponent, "Name should return path component")
    }

    // MARK: - Query Tests

    func testIsFavorite() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertFalse(favoritesManager.isFavorite(url: testURL), "Should not be favorite initially")

        favoritesManager.addFavorite(url: testURL)
        XCTAssertTrue(favoritesManager.isFavorite(url: testURL), "Should be favorite after adding")

        favoritesManager.removeFavorite(url: testURL)
        XCTAssertFalse(favoritesManager.isFavorite(url: testURL), "Should not be favorite after removing")
    }

    // MARK: - Reorder Tests

    func testMoveFavorites() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        favoritesManager.addFavorite(url: home)
        favoritesManager.addFavorite(url: desktop)
        favoritesManager.addFavorite(url: documents)

        // Move first item to last position
        favoritesManager.moveFavorites(from: IndexSet(integer: 0), to: 3)

        XCTAssertEqual(favoritesManager.favorites[0].url, desktop, "Desktop should be first")
        XCTAssertEqual(favoritesManager.favorites[1].url, documents, "Documents should be second")
        XCTAssertEqual(favoritesManager.favorites[2].url, home, "Home should be last")
    }

    // MARK: - Clear Tests

    func testClearAll() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!

        favoritesManager.addFavorite(url: home)
        favoritesManager.addFavorite(url: desktop)

        XCTAssertEqual(favoritesManager.favorites.count, 2, "Should have 2 favorites")

        favoritesManager.clearAll()
        XCTAssertEqual(favoritesManager.favorites.count, 0, "Should have no favorites after clearing")
    }

    // MARK: - Persistence Tests

    func testPersistence() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        favoritesManager.addFavorite(url: testURL, displayName: "Test Home")

        // Simulate app restart by creating new instance
        let newManager = FavoritesManager.shared

        XCTAssertEqual(newManager.favorites.count, 1, "Should load 1 favorite from persistence")
        XCTAssertEqual(newManager.favorites.first?.url, testURL, "URL should match")
        XCTAssertEqual(newManager.favorites.first?.displayName, "Test Home", "Display name should match")
    }

    // MARK: - FavoriteItem Tests

    func testFavoriteItemName() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        let favorite1 = FavoriteItem(url: testURL)
        XCTAssertEqual(favorite1.name, testURL.lastPathComponent, "Name should be path component when no custom name")

        let favorite2 = FavoriteItem(url: testURL, displayName: "Custom")
        XCTAssertEqual(favorite2.name, "Custom", "Name should be custom display name when set")
    }

    func testFavoriteItemIcon() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let favorite = FavoriteItem(url: home)
        XCTAssertEqual(favorite.iconName, "house.fill", "Home directory should have house icon")
    }

    func testFavoriteItemEquality() {
        let testURL = FileManager.default.homeDirectoryForCurrentUser
        let favorite1 = FavoriteItem(url: testURL)
        let favorite2 = FavoriteItem(url: testURL)

        XCTAssertNotEqual(favorite1.id, favorite2.id, "Each favorite should have unique ID")
    }

    // MARK: - Edge Cases

    func testAddFavoriteWithInvalidPath() {
        let invalidURL = URL(fileURLWithPath: "/this/path/does/not/exist")
        let result = favoritesManager.addFavorite(url: invalidURL)

        // Should still add (user might create the path later)
        XCTAssertTrue(result, "Should add even if path doesn't exist")
    }

    func testEmptyFavoritesList() {
        XCTAssertEqual(favoritesManager.favorites.count, 0, "Should start with empty favorites")
        XCTAssertTrue(favoritesManager.favorites.isEmpty, "Favorites should be empty")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAdditions() {
        let expectation = XCTestExpectation(description: "Concurrent favorite additions")
        expectation.expectedFulfillmentCount = 10

        let home = FileManager.default.homeDirectoryForCurrentUser

        DispatchQueue.concurrentPerform(iterations: 10) { index in
            let testURL = home.appendingPathComponent("test\(index)")
            favoritesManager.addFavorite(url: testURL)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(favoritesManager.favorites.count, 10, "Should have 10 favorites after concurrent additions")
    }
}
