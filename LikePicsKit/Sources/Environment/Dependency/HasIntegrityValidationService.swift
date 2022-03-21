//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

/// @mockable
public protocol HasIntegrityValidationService {
    var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol { get }
}
