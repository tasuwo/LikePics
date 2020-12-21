//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import ImageIO

public struct ImageSource {
    enum Value {
        case urlSet(WebImageUrlSet)
        case rawData(Data)
    }

    let identifier: UUID
    let value: Value

    // MARK: - Lifecycle

    init(urlSet: WebImageUrlSet) {
        self.identifier = UUID()
        self.value = .urlSet(urlSet)
    }

    init(rawData: Data) {
        self.identifier = UUID()
        self.value = .rawData(rawData)
    }

    // MARK: - Methods

    func resolveSize() -> CGSize? {
        switch value {
        case let .rawData(data):
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            guard
                let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
            else {
                return nil
            }
            return CGSize(width: pixelWidth, height: pixelHeight)

        case let .urlSet(urlSet):
            guard let imageSource = CGImageSourceCreateWithURL(urlSet.url as CFURL, nil) else {
                return nil
            }
            guard
                let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
            else {
                return nil
            }
            return CGSize(width: pixelWidth, height: pixelHeight)
        }
    }

    var isValid: Bool {
        guard let size = self.resolveSize() else { return false }
        return size.height != 0
            && size.width != 0
            && size.height > 10
            && size.width > 10
    }
}