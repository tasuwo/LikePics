//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

public enum ImageType: CaseIterable {
    case gif
    case jpeg
    case png
    case heic
    case webp

    public var mimeType: String {
        switch self {
        case .gif:
            return "image/gif"

        case .jpeg:
            return "image/jpeg"

        case .png:
            return "image/png"

        case .heic:
            return "image/heic"

        case .webp:
            return "image/webp"
        }
    }

    public var uniformTypeIdentifier: String {
        switch self {
        case .gif:
            return "com.compuserve.gif"

        case .jpeg:
            return "public.jpeg"

        case .png:
            return "public.png"

        case .heic:
            return "public.heic"

        case .webp:
            return "public.webp"
        }
    }
}

public extension ImageType {
    init?(_ data: Data) {
        guard let type = Self.make(by: data) else { return nil }
        self = type
    }

    private static func make(by data: Data) -> Self? {
        // https://en.wikipedia.org/wiki/JPEG
        if data.starts(with: [0xff, 0xd8, 0xff]) { return .jpeg }
        // https://en.wikipedia.org/wiki/Portable_Network_Graphics
        if data.starts(with: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) { return .png }
        // https://en.wikipedia.org/wiki/GIF
        if data.starts(with: [0x47, 0x49, 0x46]) { return .gif }
        // https://en.wikipedia.org/wiki/List_of_file_signatures
        if data.starts(with: [0x52, 0x49, 0x46, 0x46, nil, nil, nil, nil, 0x57, 0x45, 0x42, 0x50]) { return .webp }
        return nil
    }
}

private extension Data {
    func starts(with numbers: [UInt8?]) -> Bool {
        guard self.count >= numbers.count else { return false }
        return zip(numbers.indices, numbers).allSatisfy { index, number in
            guard let number = number else { return true }
            return self[index] == number
        }
    }
}
