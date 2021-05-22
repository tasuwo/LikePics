//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Smoothie

/// @mockable
public protocol ImageQueryServiceProtocol {
    func read(having id: ImageContainer.Identity) throws -> Data?
}

public struct ImageDataLoadRequest: OriginalImageRequest {
    public let imageId: UUID

    public init(imageId: UUID) {
        self.imageId = imageId
    }
}
