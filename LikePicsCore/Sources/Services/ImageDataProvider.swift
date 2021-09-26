//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie

public class ImageDataProvider {
    private let source: ImageSource
    private let _cacheKey: String
    private weak var loader: ImageSourceLoader?

    public init(source: ImageSource,
                cacheKey: String,
                loader: ImageSourceLoader)
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
        loader.load(for: source, completion: completion)
    }
}
