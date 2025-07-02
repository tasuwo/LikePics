//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

public enum ImageExtensionResolver {
    public enum Extension: String, Sendable {
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
        "image/tiff": .tiff,
    ]

    public static func resolveFileExtension(forMimeType mimeType: String) -> String? {
        return self.table[mimeType]?.rawValue
    }

    public static func resolveUTType(of url: URL) -> UTType {
        return Extension(rawValue: url.pathExtension)?.utType ?? .jpeg
    }

    public static func resolveFileExtension(for data: Data) -> String? {
        // https://en.wikipedia.org/wiki/JPEG
        if data.starts(with: [0xff, 0xd8, 0xff]) { return "jpeg" }
        // https://en.wikipedia.org/wiki/Portable_Network_Graphics
        if data.starts(with: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) { return "png" }
        // https://en.wikipedia.org/wiki/GIF
        if data.starts(with: [0x47, 0x49, 0x46]) { return "gif" }
        // https://en.wikipedia.org/wiki/List_of_file_signatures
        if data.starts(with: [0x52, 0x49, 0x46, 0x46, nil, nil, nil, nil, 0x57, 0x45, 0x42, 0x50]) { return "webp" }
        // https://en.wikipedia.org/wiki/List_of_file_signatures
        if data.starts(with: [0x4d, 0x4d, 0x00, 0x2a]) { return "tiff" }
        // https://en.wikipedia.org/wiki/List_of_file_signatures
        if data.starts(with: [0x42, 0x4d]) { return "bmp" }
        return nil
    }
}

extension Data {
    fileprivate func starts(with numbers: [UInt8?]) -> Bool {
        guard self.count >= numbers.count else { return false }
        return zip(numbers.indices, numbers).allSatisfy { index, number in
            guard let number = number else { return true }
            return self[index] == number
        }
    }
}
