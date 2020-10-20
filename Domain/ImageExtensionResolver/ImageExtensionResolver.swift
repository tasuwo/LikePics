//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import MobileCoreServices

public enum ImageExtensionResolver {
    public enum Extension: String {
        case bmp
        case gif
        case jpeg
        case png
        case tiff

        var utType: CFString? {
            switch self {
            case .bmp:
                return kUTTypeBMP

            case .gif:
                return kUTTypeGIF

            case .jpeg:
                return kUTTypeJPEG

            case .png:
                return kUTTypePNG

            case .tiff:
                return kUTTypeTIFF
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

    public static func resolveUTType(of url: URL) -> CFString {
        return Extension(rawValue: url.pathExtension)?.utType ?? kUTTypeJPEG
    }
}
