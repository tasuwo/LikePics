//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension NSItemProvider {
    func fileName() async throws -> String? {
        if let suggestedName {
            return suggestedName
        }

        if hasItemConformingToTypeIdentifier(UTType.url.identifier),
            let url = try await loadItem(forTypeIdentifier: UTType.url.identifier) as? URL
        {
            return url.lastPathComponent
        }

        if hasItemConformingToTypeIdentifier(UTType.text.identifier),
            let text = try await loadItem(forTypeIdentifier: UTType.text.identifier) as? String
        {
            return text
        }

        return nil
    }

    public func sharedItem() async throws -> SharedItem? {
        if hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
            let url = try await loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL
        {
            return .fileURL(url)
        }

        if hasItemConformingToTypeIdentifier(UTType.url.identifier),
            let url = try await loadItem(forTypeIdentifier: UTType.url.identifier) as? URL
        {
            switch url.scheme {
            case "file": return .fileURL(url)
            case "http", "https": return .webPageURL(url)
            default: break
            }
        }

        if hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return .data(_LazyImageData(self))
        }

        return nil
    }
}

private class _LazyImageData: LazyImageData {
    private let provider: NSItemProvider

    init(_ provider: NSItemProvider) {
        self.provider = provider
    }

    func fileName() async -> String? {
        try? await provider.fileName()
    }

    func resolveFilename(_ completion: @escaping (String?) -> Void) {
        Task {
            let fileName = await fileName()
            completion(fileName)
        }
    }

    func get() async -> Data? {
        guard let item = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier) else { return nil }

        if let data = item as? Data {
            return data
        }

        #if canImport(UIKit)
        if let image = item as? UIImage {
            return image.pngData()
        }
        #endif

        #if canImport(AppKit)
        if let image = item as? NSImage {
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            return rep.representation(using: .png, properties: [:])
        }
        #endif

        if let url = item as? URL, let imageData = try? Data(contentsOf: url) {
            return imageData
        }

        return nil
    }

    func fetch(_ completion: @escaping (Data?) -> Void) {
        Task {
            let data = await get()
            completion(data)
        }
    }
}
