//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie

public class ImageDataProvider {
    private let imageId: UUID
    private let _cacheKey: String
    private let imageQueryService: ImageQueryServiceProtocol

    public init(imageId: UUID,
                cacheKey: String,
                imageQueryService: ImageQueryServiceProtocol)
    {
        self.imageId = imageId
        self._cacheKey = cacheKey
        self.imageQueryService = imageQueryService
    }
}

extension ImageDataProvider: ImageDataProviding {
    public var cacheKey: String { _cacheKey }

    public func load(completion: @escaping (Data?) -> Void) {
        completion(try? imageQueryService.read(having: imageId))
    }
}
