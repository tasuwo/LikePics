//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

public struct ClipItemSource {
    enum InitializeError: Error {
        case failedToResolveSize
    }

    static let fallbackFileExtension = "jpeg"

    let index: Int
    let url: URL?
    let data: Data
    let mimeType: String?
    let height: Double
    let width: Double

    var fileName: String {
        guard let url = url else { return "\(UUID().uuidString).\(Self.fallbackFileExtension)" }
        let ext: String = {
            if let mimeType = self.mimeType {
                return ImageExtensionResolver.resolveFileExtension(forMimeType: mimeType) ?? Self.fallbackFileExtension
            } else {
                return Self.fallbackFileExtension
            }
        }()
        let name = ImageNameResolver.resolveFileName(from: url) ?? UUID().uuidString
        return "\(name).\(ext)"
    }

    // MARK: - Lifecycle

    init(index: Int, result: ImageLoaderResult) throws {
        self.index = index
        self.url = result.usedUrl
        self.data = result.data
        self.mimeType = result.mimeType

        guard let size = ImageUtility.resolveSize(for: result.data) else {
            throw InitializeError.failedToResolveSize
        }
        self.height = Double(size.height)
        self.width = Double(size.width)
    }
}
