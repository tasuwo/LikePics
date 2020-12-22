//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import ImageIO

struct ClipItemSource {
    enum InitializeError: Error {
        case failedToCreateSource
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

        guard let imageSource = CGImageSourceCreateWithData(result.data as CFData, nil) else {
            throw InitializeError.failedToCreateSource
        }
        guard
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
            let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
            let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            throw InitializeError.failedToResolveSize
        }
        let orientation: CGImagePropertyOrientation? = {
            guard let number = imageProperties[kCGImagePropertyOrientation] as? UInt32 else { return nil }
            return CGImagePropertyOrientation(rawValue: number)
        }()
        switch orientation {
        case .up, .upMirrored, .down, .downMirrored, .none:
            self.height = Double(pixelHeight)
            self.width = Double(pixelWidth)

        case .left, .leftMirrored, .right, .rightMirrored:
            self.height = Double(pixelWidth)
            self.width = Double(pixelHeight)
        }
    }
}
