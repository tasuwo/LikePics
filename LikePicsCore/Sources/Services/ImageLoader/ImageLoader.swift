//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import UIKit

public protocol ImageLoaderProtocol {
    func load(from source: ImageSource) -> Future<ImageLoaderResult, ImageLoaderError>
}

public class ImageLoader {
    private var subscriptions = Set<AnyCancellable>()

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
                return ImageLoaderResult(usedUrl: url, mimeType: response.mimeType, data: data)
            }
            .mapError { ImageLoaderError.networkError($0) }
            .eraseToAnyPublisher()
    }
}

extension ImageLoader: ImageLoaderProtocol {
    // MARK: - ImageLoaderProtocol

    public func load(from source: ImageSource) -> Future<ImageLoaderResult, ImageLoaderError> {
        switch source.value {
        case let .imageProvider(provider):
            return Future { promise in
                provider.load { data in
                    guard let data = data else {
                        promise(.failure(.internalError))
                        return
                    }
                    promise(.success(ImageLoaderResult(usedUrl: nil, mimeType: nil, data: data)))
                }
            }

        case let .fileUrl(url):
            return Future { promise in
                guard let data = try? Data(contentsOf: url) else {
                    promise(.failure(.internalError))
                    return
                }
                promise(.success(ImageLoaderResult(usedUrl: nil, mimeType: nil, data: data)))
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
