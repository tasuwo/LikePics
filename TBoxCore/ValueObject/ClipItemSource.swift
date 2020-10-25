//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CoreGraphics
import Domain
import ImageIO

struct ClipItemSource {
    static let fallbackFileExtension = "jpeg"

    let url: URL
    let data: Data
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
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
