//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CoreGraphics
import Domain
import ImageIO

struct SelectableImage {
    let imageUrl: URL
    let imageSize: CGSize

    var isValid: Bool {
        return self.imageSize.height != 0
            && self.imageSize.width != 0
            && self.imageSize.height > 10
            && self.imageSize.width > 10
    }

    // MARK: - Lifecycle

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
            .map { data, _ -> SelectableImage? in
                guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
                guard
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
                    let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
                    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
                else {
                    return nil
                }
                return SelectableImage(imageUrl: url,
                                       imageSize: CGSize(width: pixelWidth, height: pixelHeight))
            }
            .catch { _ -> AnyPublisher<SelectableImage?, Never> in
                RootLogger.shared.write(ConsoleLog(level: .info, message: "Failed to resolve size at \(url)"))
                return Just(SelectableImage?.none)
                    .eraseToAnyPublisher()
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
