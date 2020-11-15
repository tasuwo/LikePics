//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol NewImageQueryServiceProtocol {
    func read(having id: ImageContainer.Identity) throws -> Data?
}
