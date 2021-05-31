//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public class RawImageSourceProvider {
    public var viewDidLoad: PassthroughSubject<UIView, Never> = .init()
    private let providers: [ImageProvider]

    // MARK: - Lifecycle

    public init(providers: [ImageProvider]) {
        self.providers = providers
    }
}

extension RawImageSourceProvider: ImageSourceProvider {
    // MARK: - ImageSourceProvider

    public func resolveSources() -> Future<[ImageSource], ImageSourceProviderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.internalError))
                return
            }
            promise(.success(self.providers.map({ ImageSource(provider: $0) })))
        }
    }
}
