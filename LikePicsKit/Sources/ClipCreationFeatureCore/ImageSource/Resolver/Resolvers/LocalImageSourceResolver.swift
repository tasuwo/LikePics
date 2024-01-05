//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public class LocalImageSourceResolver {
    #if canImport(UIKit)
    public var loadedView: PassthroughSubject<UIView, Never> = .init()
    #endif
    #if canImport(AppKit)
    public var loadedView: PassthroughSubject<NSView, Never> = .init()
    #endif
    private let data: [LazyImageData]
    private let fileUrls: [URL]

    // MARK: - Lifecycle

    public init(data: [LazyImageData], fileURLs: [URL]) {
        self.data = data
        self.fileUrls = fileURLs
    }
}

extension LocalImageSourceResolver: ImageSourceResolver {
    // MARK: - ImageSourceResolver

    public func resolveSources() -> Future<[ImageSource], ImageSourceResolverError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }

            let loaderSources = self.data.map { ImageSource(data: $0) }
            let fileSources = self.fileUrls.map { ImageSource(fileURL: $0) }
            promise(.success(loaderSources + fileSources))
        }
    }
}
