//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Foundation
import UIKit

public class ImageLoader {
    private var subscriptions = Set<AnyCancellable>()
    private static let fallbackFileExtension = "jpeg"

    // MARK: - Initializers

    public init() {}

    // MARK: - Methods

    private static func fetchImage(for url: URL) -> AnyPublisher<ImageLoaderResult, ImageLoaderError> {
        let request: URLRequest
        if let provider = WebImageProviderPreset.resolveProvider(by: url),
           provider.shouldModifyRequest(for: url)
        {
            request = provider.modifyRequest(URLRequest(url: url))
        } else {
            request = URLRequest(url: url)
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response in
                let fileName = resolveFileName(mimeType: response.mimeType, url: url)
                return ImageLoaderResult(usedUrl: url, mimeType: response.mimeType, fileName: fileName, data: data)
            }
            .mapError { ImageLoaderError.networkError($0) }
            .eraseToAnyPublisher()
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

    public func loadData(for source: ImageLoadSource, completion: @escaping (Data?) -> Void) {
        switch source.value {
        case let .lazyLoader(loader):
            loader.load(completion)

        case let .fileUrl(url):
            guard let data = try? Data(contentsOf: url) else {
                completion(nil)
                return
            }
            completion(data)

        case let .urlSet(urlSet):
            let semaphore = DispatchSemaphore(value: 0)

            var result: Data?
            let task = URLSession.shared.dataTask(with: urlSet.url) { data, _, _ in
                result = data
                semaphore.signal()
            }
            task.resume()

            if semaphore.wait(timeout: .now() + 5) == .timedOut {
                completion(nil)
                return
            }

            completion(result)
        }
    }

    public func load(from source: ImageLoadSource) -> Future<ImageLoaderResult, ImageLoaderError> {
        switch source.value {
        case let .lazyLoader(loader):
            return Future { promise in
                loader.load { data in
                    guard let data = data else {
                        promise(.failure(.internalError))
                        return
                    }
                    loader.resolveFilename { filename in
                        promise(.success(ImageLoaderResult(usedUrl: nil,
                                                           mimeType: nil,
                                                           fileName: filename,
                                                           data: data)))
                    }
                }
            }

        case let .fileUrl(url):
            return Future { promise in
                guard let data = try? Data(contentsOf: url) else {
                    promise(.failure(.internalError))
                    return
                }
                promise(.success(ImageLoaderResult(usedUrl: nil, mimeType: nil, fileName: url.lastPathComponent, data: data)))
            }

        case let .urlSet(urlSet):
            return Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(.internalError))
                    return
                }

                if let alternativeUrl = urlSet.alternativeUrl {
                    Self.fetchImage(for: alternativeUrl)
                        .catch { _ in
                            return Self.fetchImage(for: urlSet.url)
                                .eraseToAnyPublisher()
                        }
                        .sink { completion in
                            switch completion {
                            case let .failure(error):
                                promise(.failure(error))

                            default:
                                break
                            }
                        } receiveValue: { result in
                            promise(.success(result))
                        }
                        .store(in: &self.subscriptions)
                } else {
                    Self.fetchImage(for: urlSet.url)
                        .sink { completion in
                            switch completion {
                            case let .failure(error):
                                promise(.failure(error))

                            default:
                                break
                            }
                        } receiveValue: { result in
                            promise(.success(result))
                        }
                        .store(in: &self.subscriptions)
                }
            }
        }
    }
}