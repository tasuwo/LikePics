//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie

public class ImageDataProvider {
    private let source: ImageLoadSource
    private let _cacheKey: String
    private weak var loader: ImageLoadable?

    public init(source: ImageLoadSource,
                cacheKey: String,
                loader: ImageLoadable)
    {
        self.source = source
        self._cacheKey = cacheKey
        self.loader = loader
    }
}

extension ImageDataProvider: ImageDataProviding {
    public var cacheKey: String { _cacheKey }

    public func load(completion: @escaping (Data?) -> Void) {
        guard let loader = self.loader else {
            completion(nil)
            return
        }
        loader.loadData(for: source, completion: completion)
    }
}
