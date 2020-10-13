//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CoreGraphics
import Domain
import ImageIO

struct DisplayableImageMeta {
    let imageUrl: URL
    let thumbImageUrl: URL?
    let imageSize: CGSize

    var isValid: Bool {
        return self.imageSize.height != 0
            && self.imageSize.width != 0
            && self.imageSize.height > 10
            && self.imageSize.width > 10
    }

    // MARK: - Lifecycle

    static func make(by urlSet: WebImageUrlSet, using session: URLSession) -> AnyPublisher<Self, Never> {
        let targetUrl = urlSet.lowQualityUrl ?? urlSet.url
        let request: URLRequest
        if let provider = WebImageProviderPreset.resolveProvider(by: targetUrl),
            provider.shouldModifyRequest(for: targetUrl)
        {
            request = provider.modifyRequest(URLRequest(url: targetUrl))
        } else {
            request = URLRequest(url: targetUrl)
        }

        return session
            .dataTaskPublisher(for: request)
            .map { data, _ -> DisplayableImageMeta? in
                guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
                guard
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
                    let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
                    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
                else {
                    return nil
                }
                return DisplayableImageMeta(imageUrl: urlSet.url,
                                            thumbImageUrl: urlSet.lowQualityUrl,
                                            imageSize: CGSize(width: pixelWidth, height: pixelHeight))
            }
            .catch { meta -> AnyPublisher<DisplayableImageMeta?, Never> in
                RootLogger.shared.write(ConsoleLog(level: .info, message: "Failed to resolve size at \(targetUrl)"))
                return Just(Optional<DisplayableImageMeta>.none)
                    .eraseToAnyPublisher()
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
