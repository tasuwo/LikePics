//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Foundation

public class ImageLoader {
    private var subscriptions = Set<AnyCancellable>()
    private static let fallbackFileExtension = "jpeg"

    // MARK: - Initializers

    public init() {}

    // MARK: - Methods

    private static func image(from url: URL) async throws -> LoadedImage {
        let request: URLRequest
        if let provider = WebImageProviderPreset.resolveProvider(by: url),
           provider.shouldModifyRequest(for: url)
        {
            request = provider.modifyRequest(URLRequest(url: url))
        } else {
            request = URLRequest(url: url)
        }

        return try await image(for: request)
    }

    private static func image(for request: URLRequest, delaySeconds: TimeInterval? = nil, retryCount: Int = 0) async throws -> LoadedImage {
        if let delaySeconds {
            try await Task.sleep(nanoseconds: UInt64(1000000000 * delaySeconds))
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw ImageLoaderError.internalError
        }

        guard 200 ..< 300 ~= response.statusCode else {
            if response.statusCode == 429 || 500 ..< 600 ~= response.statusCode {
                guard retryCount < 5 else {
                    throw ImageLoaderError.tooManyRequest
                }

                let nextRetryCount: Int = retryCount + 1
                let delaySeconds: Double

                if let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap({ TimeInterval($0) }) {
                    delaySeconds = retryAfter
                } else {
                    delaySeconds = pow(2, TimeInterval(nextRetryCount)) + (TimeInterval.random(in: 0 ..< 1000) / 1000)
                }

                return try await image(for: request, delaySeconds: delaySeconds, retryCount: nextRetryCount)
            } else {
                throw ImageLoaderError.invalidStatusCode
            }
        }

        let fileName = resolveFileName(mimeType: response.mimeType, url: request.url!)
        return LoadedImage(usedUrl: request.url!,
                           mimeType: response.mimeType,
                           fileName: fileName,
                           data: data)
    }

    private static func resolveFileName(mimeType: String?, url: URL) -> String? {
        let ext: String = {
            if let mimeType = mimeType {
                return ImageExtensionResolver.resolveFileExtension(forMimeType: mimeType) ?? Self.fallbackFileExtension
            } else {
                return Self.fallbackFileExtension
            }
        }()
        guard let name = ImageNameResolver.resolveFileName(from: url) else {
            return nil
        }
        return "\(name).\(ext)"
    }
}

extension ImageLoader: ImageLoadable {
    // MARK: - ImageLoadable

    public func data(for source: ImageSource) async -> Data? {
        switch source.value {
        case let .data(data):
            return await data.get()

        case let .fileURL(url):
            return try? Data(contentsOf: url)

        case let .webURL(urlSet):
            if let alternativeUrl = urlSet.alternativeUrl, let data = try? await Self.image(for: URLRequest(url: alternativeUrl)).data {
                return data
            }
            return try? await Self.image(for: URLRequest(url: urlSet.url)).data
        }
    }

    public func image(from source: ImageSource) async throws -> LoadedImage {
        switch source.value {
        case let .data(lazyData):
            guard let data = await lazyData.get() else {
                throw ImageLoaderError.internalError
            }
            let fileName = await lazyData.fileName()
            return .init(usedUrl: nil,
                         mimeType: nil,
                         fileName: fileName,
                         data: data)

        case let .fileURL(url):
            guard let data = try? Data(contentsOf: url) else {
                throw ImageLoaderError.internalError
            }
            return .init(usedUrl: nil,
                         mimeType: nil,
                         fileName: url.lastPathComponent,
                         data: data)

        case let .webURL(urlSet):
            if let alternativeUrl = urlSet.alternativeUrl, let image = try? await Self.image(for: URLRequest(url: alternativeUrl)) {
                return image
            }
            return try await Self.image(for: URLRequest(url: urlSet.url))
        }
    }

    public func load(from source: ImageSource) -> Future<LoadedImage, ImageLoaderError> {
        switch source.value {
        case let .data(lazyData):
            return Future { promise in
                lazyData.fetch { data in
                    guard let data = data else {
                        promise(.failure(.internalError))
                        return
                    }
                    lazyData.resolveFilename { filename in
                        promise(.success(LoadedImage(usedUrl: nil,
                                                     mimeType: nil,
                                                     fileName: filename,
                                                     data: data)))
                    }
                }
            }

        case let .fileURL(url):
            return Future { promise in
                guard let data = try? Data(contentsOf: url) else {
                    promise(.failure(.internalError))
                    return
                }
                promise(.success(LoadedImage(usedUrl: nil, mimeType: nil, fileName: url.lastPathComponent, data: data)))
            }

        case let .webURL(urlSet):
            return Future { promise in
                Task {
                    do {
                        if let alternativeUrl = urlSet.alternativeUrl, let image = try? await Self.image(for: URLRequest(url: alternativeUrl)) {
                            promise(.success(image))
                        }
                        let image = try await Self.image(for: URLRequest(url: urlSet.url))
                        promise(.success(image))
                    } catch {
                        promise(.failure(.internalError))
                    }
                }
            }
        }
    }
}
