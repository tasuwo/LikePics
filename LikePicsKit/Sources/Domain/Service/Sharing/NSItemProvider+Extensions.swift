//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

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

    func imageSource() async throws -> ImageSource? {
        if hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
           let url = try await loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL
        {
            return .fileUrl(url)
        }

        if hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = try await loadItem(forTypeIdentifier: UTType.url.identifier) as? URL
        {
            switch url.scheme {
            case "file": return .fileUrl(url)
            case "http", "https": return .webUrl(url)
            default: break
            }
        }

        if hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let item = try await loadItem(forTypeIdentifier: UTType.image.identifier)

            if let data = item as? Data {
                return .data(data)
            }

            #if canImport(UIKit)
            if let image = item as? UIImage {
                return .uiImage(image)
            }
            #endif

            #if canImport(AppKit)
            if let image = item as? NSImage {
                return .nsImage(image)
            }
            #endif
        }

        return nil
    }
}
