//
//  QuickLookService.swift
//  FilePilot
//
//  Handles Quick Look thumbnails and previews
//

import Foundation
import QuickLookThumbnailing
import QuickLookUI
import AppKit

@MainActor
class QuickLookService: ObservableObject {
    static let shared = QuickLookService()

    private let thumbnailCache = NSCache<NSURL, NSImage>()
    private let generator = QLThumbnailGenerator.shared

    init() {
        thumbnailCache.countLimit = 100
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    /// Generate thumbnail for a file
    func generateThumbnail(for url: URL, size: CGSize) async throws -> NSImage {
        // Check cache first
        if let cached = thumbnailCache.object(forKey: url as NSURL) {
            return cached
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .all
        )

        return try await withCheckedThrowingContinuation { continuation in
            generator.generateBestRepresentation(for: request) { representation, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let representation = representation else {
                    continuation.resume(throwing: QuickLookError.noRepresentation)
                    return
                }

                let image: NSImage
                if let nsImage = representation.nsImage {
                    image = nsImage
                } else if let cgImage = representation.cgImage {
                    image = NSImage(cgImage: cgImage, size: size)
                } else {
                    continuation.resume(throwing: QuickLookError.noImage)
                    return
                }

                // Cache the result
                self.thumbnailCache.setObject(image, forKey: url as NSURL)
                continuation.resume(returning: image)
            }
        }
    }

    /// Generate multiple thumbnails in batch
    func generateThumbnails(for urls: [URL], size: CGSize) async -> [URL: NSImage] {
        var results: [URL: NSImage] = [:]

        await withTaskGroup(of: (URL, NSImage?).self) { group in
            for url in urls {
                group.addTask {
                    do {
                        let image = try await self.generateThumbnail(for: url, size: size)
                        return (url, image)
                    } catch {
                        print("Failed to generate thumbnail for \(url): \(error)")
                        return (url, nil)
                    }
                }
            }

            for await (url, image) in group {
                if let image = image {
                    results[url] = image
                }
            }
        }

        return results
    }

    /// Cancel all pending thumbnail requests
    func cancelAllRequests() {
        generator.cancel(allRequests)
    }

    /// Clear thumbnail cache
    func clearCache() {
        thumbnailCache.removeAllObjects()
    }

    enum QuickLookError: LocalizedError {
        case noRepresentation
        case noImage

        var errorDescription: String? {
            switch self {
            case .noRepresentation:
                return "Could not generate thumbnail representation"
            case .noImage:
                return "Could not extract image from representation"
            }
        }
    }
}

// MARK: - Quick Look Preview Panel Wrapper

import SwiftUI

struct QuickLookPreview: NSViewRepresentable {
    let urls: [URL]
    @Binding var currentIndex: Int

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Quick Look panel is managed separately
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(urls: urls, currentIndex: $currentIndex)
    }

    class Coordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
        let urls: [URL]
        @Binding var currentIndex: Int

        init(urls: [URL], currentIndex: Binding<Int>) {
            self.urls = urls
            self._currentIndex = currentIndex
            super.init()
        }

        func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
            return urls.count
        }

        func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
            return urls[index] as NSURL
        }

        func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
            if event.type == .keyDown {
                switch event.keyCode {
                case 49: // Space
                    if QLPreviewPanel.shared().isVisible {
                        QLPreviewPanel.shared().orderOut(nil)
                    } else {
                        showPreview()
                    }
                    return true
                case 53: // Escape
                    QLPreviewPanel.shared().orderOut(nil)
                    return true
                default:
                    break
                }
            }
            return false
        }

        func showPreview() {
            let panel = QLPreviewPanel.shared()!
            panel.dataSource = self
            panel.delegate = self
            panel.currentPreviewItemIndex = currentIndex
            panel.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    func quickLookPreview(urls: [URL], currentIndex: Binding<Int>) -> some View {
        self.background(
            QuickLookPreview(urls: urls, currentIndex: currentIndex)
                .frame(width: 0, height: 0)
                .opacity(0)
        )
    }
}