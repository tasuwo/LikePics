//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

public protocol HasIntegrityValidationService {
    var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol { get }
}
