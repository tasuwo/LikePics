//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

/// @mockable
public protocol ImageQueryServiceProtocol: AnyObject {
    func read(having id: ImageContainer.Identity) throws -> Data?
}
