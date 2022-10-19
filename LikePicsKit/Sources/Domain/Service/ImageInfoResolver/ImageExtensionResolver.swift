//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

public enum ImageExtensionResolver {
    public enum Extension: String {
        case bmp
        case gif
        case jpeg
        case png
        case tiff

        var utType: UTType {
            switch self {
            case .bmp:
                return .bmp

            case .gif:
                return .gif

            case .jpeg:
                return .jpeg

            case .png:
                return .png

            case .tiff:
                return .tiff
            }
        }
    }

    private static let table: [String: Extension] = [
        "image/bmp": .bmp,
        "image/gif": .gif,
        "image/jpeg": .jpeg,
        "image/png": .png,
        "image/tiff": .tiff
    ]

    public static func resolveFileExtension(forMimeType mimeType: String) -> String? {
        return self.table[mimeType]?.rawValue
    }

    public static func resolveUTType(of url: URL) -> UTType {
        return Extension(rawValue: url.pathExtension)?.utType ?? .jpeg
    }
}
