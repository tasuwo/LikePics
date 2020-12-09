//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum TagCommandServiceError: Error {
    case duplicated
    case internalError
}

public protocol TagCommandServiceProtocol {
    func create(tagWithName name: String) -> Result<Void, TagCommandServiceError>
}
