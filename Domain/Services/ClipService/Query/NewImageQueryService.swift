//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Smoothie

/// @mockable
public protocol NewImageQueryServiceProtocol {
    func read(having id: ImageContainer.Identity) throws -> Data?
}

public struct NewImageDataLoadRequest: OriginalImageRequest {
    public let imageId: UUID

    public init(imageId: UUID) {
        self.imageId = imageId
    }
}
