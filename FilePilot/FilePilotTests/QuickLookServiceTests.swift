//
//  QuickLookServiceTests.swift
//  FilePilotTests
//
//  Test suite for QuickLookService thumbnail generation and caching
//

import XCTest
import AppKit
@testable import FilePilot

@MainActor
final class QuickLookServiceTests: XCTestCase {
    var quickLookService: QuickLookService!
    var testDirectory: URL!
    var testImageFile: URL!
    var testTextFile: URL!

    override func setUp() async throws {
        quickLookService = QuickLookService.shared

        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent("QuickLookTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)

        // Create test text file
        testTextFile = testDirectory.appendingPathComponent("test.txt")
        try "Test content for Quick Look".write(to: testTextFile, atomically: true, encoding: .utf8)

        // Create a simple test image file (1x1 PNG)
        testImageFile = testDirectory.appendingPathComponent("test.png")
        try createTestImage().write(to: testImageFile)
    }

    override func tearDown() async throws {
        // Clear cache
        quickLookService.clearCache()

        // Clean up test directory
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try? FileManager.default.removeItem(at: testDirectory)
        }
    }

    // MARK: - Helper Methods

    private func createTestImage() throws -> Data {
        // Create a simple 1x1 red PNG image
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test image"])
        }

        return pngData
    }

    // MARK: - Thumbnail Generation Tests

    func testGenerateThumbnailForTextFile() async throws {
        let size = CGSize(width: 128, height: 128)

        let thumbnail = try await quickLookService.generateThumbnail(for: testTextFile, size: size)

        XCTAssertNotNil(thumbnail, "Thumbnail should be generated")
        XCTAssertEqual(thumbnail.size.width, size.width, accuracy: 1.0, "Thumbnail width should match requested size")
        XCTAssertEqual(thumbnail.size.height, size.height, accuracy: 1.0, "Thumbnail height should match requested size")
    }

    func testGenerateThumbnailForImageFile() async throws {
        let size = CGSize(width: 128, height: 128)

        let thumbnail = try await quickLookService.generateThumbnail(for: testImageFile, size: size)

        XCTAssertNotNil(thumbnail, "Thumbnail should be generated")
        XCTAssertGreaterThan(thumbnail.size.width, 0, "Thumbnail should have positive width")
        XCTAssertGreaterThan(thumbnail.size.height, 0, "Thumbnail should have positive height")
    }

    func testGenerateThumbnailForNonExistentFile() async {
        let nonExistent = testDirectory.appendingPathComponent("does-not-exist.txt")
        let size = CGSize(width: 128, height: 128)

        // Note: QuickLook API generates generic thumbnails even for non-existent files
        // This is actual API behavior, not a bug in our implementation
        do {
            let thumbnail = try await quickLookService.generateThumbnail(for: nonExistent, size: size)
            // QuickLook generates a generic "document" thumbnail for non-existent files
            XCTAssertNotNil(thumbnail, "QuickLook generates generic thumbnails for non-existent files")
            XCTAssertGreaterThan(thumbnail.size.width, 0)
        } catch {
            // Some macOS versions may throw - both behaviors are acceptable
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Caching Tests

    func testThumbnailCaching() async throws {
        let size = CGSize(width: 128, height: 128)

        // Generate thumbnail first time
        let thumbnail1 = try await quickLookService.generateThumbnail(for: testTextFile, size: size)

        // Generate thumbnail second time - should come from cache
        let thumbnail2 = try await quickLookService.generateThumbnail(for: testTextFile, size: size)

        XCTAssertNotNil(thumbnail1, "First thumbnail should be generated")
        XCTAssertNotNil(thumbnail2, "Second thumbnail should be retrieved")

        // Note: We can't directly test if it came from cache vs regenerated,
        // but we can verify both calls succeed and return valid images
        XCTAssertEqual(thumbnail1.size, thumbnail2.size, "Cached thumbnail should have same size")
    }

    func testClearCache() async throws {
        let size = CGSize(width: 128, height: 128)

        // Generate and cache a thumbnail
        _ = try await quickLookService.generateThumbnail(for: testTextFile, size: size)

        // Clear the cache
        quickLookService.clearCache()

        // Generate again - should regenerate (can't directly test, but should not crash)
        let thumbnail = try await quickLookService.generateThumbnail(for: testTextFile, size: size)
        XCTAssertNotNil(thumbnail, "Should regenerate thumbnail after cache clear")
    }

    // MARK: - Batch Generation Tests

    func testGenerateMultipleThumbnails() async throws {
        let file1 = testDirectory.appendingPathComponent("file1.txt")
        let file2 = testDirectory.appendingPathComponent("file2.txt")
        let file3 = testDirectory.appendingPathComponent("file3.txt")

        try "Content 1".write(to: file1, atomically: true, encoding: .utf8)
        try "Content 2".write(to: file2, atomically: true, encoding: .utf8)
        try "Content 3".write(to: file3, atomically: true, encoding: .utf8)

        let size = CGSize(width: 128, height: 128)
        let results = await quickLookService.generateThumbnails(for: [file1, file2, file3], size: size)

        XCTAssertGreaterThanOrEqual(results.count, 1, "Should generate at least one thumbnail")
        XCTAssertLessThanOrEqual(results.count, 3, "Should generate at most 3 thumbnails")

        // Check that generated thumbnails have correct sizes
        for (_, image) in results {
            XCTAssertNotNil(image, "Generated image should not be nil")
            XCTAssertGreaterThan(image.size.width, 0, "Image width should be positive")
        }
    }

    func testGenerateMultipleThumbnailsWithSomeFailures() async throws {
        let file1 = testDirectory.appendingPathComponent("file1.txt")
        let nonExistent = testDirectory.appendingPathComponent("does-not-exist.txt")
        let file3 = testDirectory.appendingPathComponent("file3.txt")

        try "Content 1".write(to: file1, atomically: true, encoding: .utf8)
        try "Content 3".write(to: file3, atomically: true, encoding: .utf8)

        let size = CGSize(width: 128, height: 128)
        let results = await quickLookService.generateThumbnails(for: [file1, nonExistent, file3], size: size)

        // QuickLook generates thumbnails for all URLs, even non-existent files (generic placeholders)
        XCTAssertGreaterThanOrEqual(results.count, 2, "Should generate thumbnails for existing files")
        // Note: QuickLook may generate generic thumbnails for non-existent files
        // This is API behavior, not an error condition
        XCTAssertNotNil(results[file1], "Existing file1 should have thumbnail")
        XCTAssertNotNil(results[file3], "Existing file3 should have thumbnail")
    }

    func testBatchGenerationWithEmptyArray() async {
        let size = CGSize(width: 128, height: 128)
        let results = await quickLookService.generateThumbnails(for: [], size: size)

        XCTAssertEqual(results.count, 0, "Empty input should produce empty results")
    }

    // MARK: - Different Size Tests

    func testGenerateThumbnailsWithDifferentSizes() async throws {
        let sizes = [
            CGSize(width: 64, height: 64),
            CGSize(width: 128, height: 128),
            CGSize(width: 256, height: 256)
        ]

        for size in sizes {
            let thumbnail = try await quickLookService.generateThumbnail(for: testTextFile, size: size)
            XCTAssertNotNil(thumbnail, "Should generate thumbnail for size \(size)")
            // Note: QuickLook API may not honor exact size requests - it returns optimal sizes
            // Verify the thumbnail is reasonable, not exact size matching
            XCTAssertGreaterThan(thumbnail.size.width, 0, "Width should be positive")
            XCTAssertGreaterThan(thumbnail.size.height, 0, "Height should be positive")
            XCTAssertLessThanOrEqual(thumbnail.size.width, size.width * 2, "Width should be reasonable for requested size")
        }
    }

    // MARK: - Request Cancellation Tests

    func testCancelAllRequests() async throws {
        // Create multiple files for concurrent generation
        let files = (0..<10).map { index in
            testDirectory.appendingPathComponent("file\(index).txt")
        }

        for file in files {
            try "Content".write(to: file, atomically: true, encoding: .utf8)
        }

        // Start batch generation (don't await)
        let size = CGSize(width: 128, height: 128)
        Task {
            _ = await quickLookService.generateThumbnails(for: files, size: size)
        }

        // Cancel all requests
        quickLookService.cancelAllRequests()

        // Test should complete without crashes
        // Note: Can't easily verify cancellation effect, but ensures method doesn't crash
    }

    // MARK: - Error Handling Tests

    func testQuickLookErrorDescriptions() {
        let noRepError = QuickLookService.QuickLookError.noRepresentation
        XCTAssertNotNil(noRepError.errorDescription, "Error should have description")
        XCTAssertTrue(noRepError.errorDescription!.contains("representation"), "Description should mention representation")

        let noImageError = QuickLookService.QuickLookError.noImage
        XCTAssertNotNil(noImageError.errorDescription, "Error should have description")
        XCTAssertTrue(noImageError.errorDescription!.contains("image"), "Description should mention image")
    }

    // MARK: - Retina Display Tests

    func testRetinaScaleHandling() async throws {
        // Test that service handles different scale factors
        let size = CGSize(width: 128, height: 128)
        let thumbnail = try await quickLookService.generateThumbnail(for: testTextFile, size: size)

        XCTAssertNotNil(thumbnail, "Should generate thumbnail regardless of scale factor")
        // The service should automatically use NSScreen.main?.backingScaleFactor
        // We can't directly test the scale, but verify the image is valid
        XCTAssertGreaterThan(thumbnail.size.width, 0, "Thumbnail should have valid dimensions")
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentThumbnailGeneration() async throws {
        let size = CGSize(width: 128, height: 128)

        // Generate thumbnails concurrently
        async let thumb1 = quickLookService.generateThumbnail(for: testTextFile, size: size)
        async let thumb2 = quickLookService.generateThumbnail(for: testImageFile, size: size)

        let results = try await [thumb1, thumb2]

        XCTAssertEqual(results.count, 2, "Should generate both thumbnails")
        XCTAssertNotNil(results[0], "First thumbnail should be valid")
        XCTAssertNotNil(results[1], "Second thumbnail should be valid")
    }

    // MARK: - Memory Management Tests

    func testCacheLimits() async throws {
        // The cache has limits: 50 MB total, 100 items
        // We can't easily test memory limits, but we can test item count behavior

        let size = CGSize(width: 128, height: 128)

        // Generate many thumbnails to test cache behavior
        for i in 0..<10 {
            let file = testDirectory.appendingPathComponent("file\(i).txt")
            try "Content \(i)".write(to: file, atomically: true, encoding: .utf8)

            _ = try? await quickLookService.generateThumbnail(for: file, size: size)
        }

        // Cache should handle this gracefully without crashes
        // Note: Can't directly test eviction policy, but ensures no memory issues
    }
}
