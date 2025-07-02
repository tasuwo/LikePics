//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public enum ImageUtility {}

extension ImageUtility {
    // MARK: - Resolve Size

    public static func resolveSize(for data: Data) -> CGSize? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        return self.resolveSize(for: imageSource)
    }

    private static func resolveSize(for imageSource: CGImageSource) -> CGSize? {
        guard
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
            let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
            let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            return nil
        }
        let orientation: CGImagePropertyOrientation? = {
            guard let number = imageProperties[kCGImagePropertyOrientation] as? UInt32 else { return nil }
            return CGImagePropertyOrientation(rawValue: number)
        }()
        switch orientation {
        case .up, .upMirrored, .down, .downMirrored, .none:
            return CGSize(width: pixelWidth, height: pixelHeight)

        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: pixelHeight, height: pixelWidth)
        }
    }
}

extension ImageUtility {
    // MARK: - Downsampling

    #if canImport(UIKit)
    static func downsampling(imageAt imageUrl: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, imageSourceOptions) else { return nil }
        return self.downsampling(imageSource, to: pointSize, scale: scale)
    }

    static func downsampling(_ data: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        return self.downsampling(imageSource, to: pointSize, scale: scale)
    }

    private static func downsampling(_ imageSource: CGImageSource, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let options =
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels,
            ] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
    #endif
    #if canImport(AppKit)
    static func downsampling(imageAt imageUrl: URL, to pointSize: CGSize, scale: CGFloat) -> NSImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, imageSourceOptions) else { return nil }
        return self.downsampling(imageSource, to: pointSize, scale: scale)
    }

    static func downsampling(_ data: Data, to pointSize: CGSize, scale: CGFloat) -> NSImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        return self.downsampling(imageSource, to: pointSize, scale: scale)
    }

    private static func downsampling(_ imageSource: CGImageSource, to pointSize: CGSize, scale: CGFloat) -> NSImage? {
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let options =
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels,
            ] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
        return NSImage(cgImage: downsampledImage, size: .init(width: downsampledImage.width, height: downsampledImage.height))
    }
    #endif
}
