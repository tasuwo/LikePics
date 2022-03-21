//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum TagCommandServiceError: Error {
    case duplicated
    case internalError
}

/// @mockable
public protocol TagCommandServiceProtocol {
    func create(tagWithName name: String) -> Result<Tag.Identity, TagCommandServiceError>
}
