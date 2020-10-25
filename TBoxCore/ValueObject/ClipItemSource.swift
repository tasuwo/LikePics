//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CoreGraphics
import Domain
import ImageIO
import UIKit

struct ClipItemSource {
    static let fallbackFileExtension = "jpeg"

    let url: URL
    let data: Data
    let thumbnail: UIImage
    let mimeType: String?
    let height: Double
    let width: Double

    var isValid: Bool {
        return self.height != 0 && self.width != 0 && self.height > 10 && self.width > 10
    }

    var fileName: String {
        let ext: String = {
            if let mimeType = self.mimeType {
                return ImageExtensionResolver.resolveFileExtension(forMimeType: mimeType) ?? Self.fallbackFileExtension
            } else {
                return Self.fallbackFileExtension
            }
        }()
        let name = WebImageNameResolver.resolveFileName(from: self.url) ?? UUID().uuidString
        return "\(name).\(ext)"
    }

    // MARK: - Methods

    static func make(by url: URL, using session: URLSession) -> AnyPublisher<Self, Never> {
        let request: URLRequest
        if let provider = WebImageProviderPreset.resolveProvider(by: url),
            provider.shouldModifyRequest(for: url)
        {
            request = provider.modifyRequest(URLRequest(url: url))
        } else {
            request = URLRequest(url: url)
        }

        return session
            .dataTaskPublisher(for: request)
            .map { data, response -> ClipItemSource? in
                guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
                guard
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
                    let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
                    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
                else {
                    return nil
                }

                let downsampleSize = Self.calcDownsamplingSize(forOriginalSize: CGSize(width: pixelWidth, height: pixelHeight))
                guard let thumbnail = Self.downsampledImage(data: data, to: downsampleSize) else { return nil }

                return ClipItemSource(url: url,
                                      data: data,
                                      thumbnail: thumbnail,
                                      mimeType: response.mimeType,
                                      height: Double(pixelHeight),
                                      width: Double(pixelWidth))
            }
            .catch { _ -> AnyPublisher<ClipItemSource?, Never> in
                RootLogger.shared.write(ConsoleLog(level: .info, message: "Failed to resolve size at \(url)"))
                return Just(ClipItemSource?.none)
                    .eraseToAnyPublisher()
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    // TODO: ThumbnailStorageProtocol のロジックと共通化すべきか検討する

    private static func calcScale(forSize source: CGSize, toFit destination: CGSize) -> CGFloat {
        let widthScale = destination.width / source.width
        let heightScale = destination.height / source.height
        return min(widthScale, heightScale)
    }

    private static func calcDownsamplingSize(forOriginalSize imageSize: CGSize) -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        let rotatedScreenSize = CGSize(width: UIScreen.main.bounds.size.height,
                                       height: UIScreen.main.bounds.size.width)

        let scaleToFitScreen = max(self.calcScale(forSize: imageSize, toFit: screenSize),
                                   self.calcScale(forSize: imageSize, toFit: rotatedScreenSize))
        let targetScale = min(1, scaleToFitScreen)

        return imageSize.scaled(by: targetScale)
    }

    private static func downsampledImage(data: Data, to pointSize: CGSize) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height)
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }
}

private extension CGSize {
    func scaled(by scale: CGFloat) -> Self {
        return .init(width: self.width * scale, height: self.height * scale)
    }
}
