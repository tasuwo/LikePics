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

public class ImageSourcePassthrough {
    #if canImport(UIKit)
    public var loadedView: PassthroughSubject<UIView, Never> = .init()
    #endif
    #if canImport(AppKit)
    public var loadedView: PassthroughSubject<NSView, Never> = .init()
    #endif
    private let sources: [ImageSource]

    // MARK: - Lifecycle

    public init(_ sources: [ImageSource]) {
        self.sources = sources
    }
}

extension ImageSourcePassthrough: ImageSourceResolver {
    // MARK: - ImageSourceResolver

    public func resolveSources() -> Future<[ImageSource], ImageSourceResolverError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }
            promise(.success(self.sources))
        }
    }
}
