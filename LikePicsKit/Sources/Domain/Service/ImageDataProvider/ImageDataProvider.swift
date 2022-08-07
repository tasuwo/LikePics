//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation
import Smoothie

public class ImageDataProvider {
    private let imageId: UUID
    private let _cacheKey: String
    private weak var imageQueryService: ImageQueryServiceProtocol?

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
        guard let service = self.imageQueryService else {
            completion(nil)
            return
        }
        completion(try? service.read(having: imageId))
    }
}
