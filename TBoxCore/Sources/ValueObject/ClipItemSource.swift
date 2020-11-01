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
    let mimeType: String?
    let height: Double
    let width: Double

    var fileName: String {
        let ext: String = {
            if let mimeType = self.mimeType {
                return ImageExtensionResolver.resolveFileExtension(forMimeType: mimeType) ?? Self.fallbackFileExtension
            } else {
                return Self.fallbackFileExtension
            }
        }()
        let name = ImageNameResolver.resolveFileName(from: self.url) ?? UUID().uuidString
        return "\(name).\(ext)"
    }

    // MARK: - Methods

    static func make(by selectableImage: SelectableImage, using session: URLSession) -> AnyPublisher<Self, Never> {
        if let alternativeUrl = selectableImage.alternativeUrl {
            return self.fetchImage(at: alternativeUrl, in: selectableImage, using: session)
                .flatMap { image -> AnyPublisher<Self, Never> in
                    if let image = image {
                        return Just(image)
                            .setFailureType(to: Never.self)
                            .eraseToAnyPublisher()
                    } else {
                        return self.fetchImage(at: selectableImage.url, in: selectableImage, using: session)
                            .compactMap { $0 }
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        } else {
            return self.fetchImage(at: selectableImage.url, in: selectableImage, using: session)
                .compactMap { $0 }
                .eraseToAnyPublisher()
        }
    }

    private static func fetchImage(at url: URL, in selectableImage: SelectableImage, using session: URLSession) -> AnyPublisher<Self?, Never> {
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

                return ClipItemSource(url: url,
                                      data: data,
                                      mimeType: response.mimeType,
                                      height: Double(pixelHeight),
                                      width: Double(pixelWidth))
            }
            .catch { _ -> AnyPublisher<ClipItemSource?, Never> in
                RootLogger.shared.write(ConsoleLog(level: .info, message: "Failed to resolve size at \(url)"))
                return Just(ClipItemSource?.none)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
