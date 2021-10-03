//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public class LocalImageLoadSourceResolver {
    public var loadedView: PassthroughSubject<UIView, Never> = .init()
    private let loaders: [ImageLazyLoadable]
    private let fileUrls: [URL]

    // MARK: - Lifecycle

    public init(loaders: [ImageLazyLoadable], fileUrls: [URL]) {
        self.loaders = loaders
        self.fileUrls = fileUrls
    }
}

extension LocalImageLoadSourceResolver: ImageLoadSourceResolver {
    // MARK: - ImageLoadSourceResolver

    public func resolveSources() -> Future<[ImageLoadSource], ImageLoadSourceResolverError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            let loaderSources = self.loaders.map { ImageLoadSource(lazyLoader: $0) }
            let fileSources = self.fileUrls.map { ImageLoadSource(fileUrl: $0) }
            promise(.success(loaderSources + fileSources))
        }
    }
}
