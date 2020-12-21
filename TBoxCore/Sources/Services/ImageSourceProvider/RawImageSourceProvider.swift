//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public class RawImageSourceProvider {
    public var viewDidLoad: PassthroughSubject<UIView, Never> = .init()
    private let imageDataSet: [Data]

    // MARK: - Lifecycle

    public init(imageDataSet: [Data]) {
        self.imageDataSet = imageDataSet
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
            promise(.success(self.imageDataSet.map({ ImageSource(rawData: $0) })))
        }
    }
}
