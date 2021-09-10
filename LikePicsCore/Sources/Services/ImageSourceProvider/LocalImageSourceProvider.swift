//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public class LocalImageSourceProvider {
    public var viewDidLoad: PassthroughSubject<UIView, Never> = .init()
    private let providers: [ImageProvider]
    private let fileUrls: [URL]

    // MARK: - Lifecycle

    public init(providers: [ImageProvider],
                fileUrls: [URL])
    {
        self.providers = providers
        self.fileUrls = fileUrls
    }
}

extension LocalImageSourceProvider: ImageSourceProvider {
    // MARK: - ImageSourceProvider

    public func resolveSources() -> Future<[ImageSource], ImageSourceProviderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            let providerSources = self.providers.map { ImageSource(provider: $0) }
            let fileSources = self.fileUrls.map { ImageSource(fileUrl: $0) }
            promise(.success(providerSources + fileSources))
        }
    }
}
