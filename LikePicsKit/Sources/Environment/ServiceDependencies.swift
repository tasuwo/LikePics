//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit

public protocol HasClipCommandService {
    var clipCommandService: ClipCommandServiceProtocol { get }
}

public protocol HasClipQueryService {
    var clipQueryService: ClipQueryServiceProtocol { get }
}

public protocol HasClipSearchHistoryService {
    var clipSearchHistoryService: ClipSearchHistoryService { get }
}

public protocol HasClipSearchSettingService {
    var clipSearchSettingService: ClipSearchSettingService { get }
}

public protocol HasCloudAvailabilityService {
    var cloudAvailabilityService: CloudAvailabilityServiceProtocol { get }
}

public protocol HasImageQueryService {
    var imageQueryService: ImageQueryServiceProtocol { get }
}

public protocol HasIntegrityValidationService {
    var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol { get }
}

public protocol HasNop {}

public protocol HasPasteboard {
    var pasteboard: Pasteboard { get }
}

public protocol HasRouter {
    var router: Router { get }
}

public protocol HasTemporariesPersistService {
    var temporariesPersistService: TemporariesPersistServiceProtocol { get }
}

public protocol HasTextValidator {
    var textValidator: (String?) -> Bool { get }
}

public protocol HasTransitionLock {
    var transitionLock: TransitionLock { get }
}

public protocol HasUserSettingStorage {
    var userSettingStorage: UserSettingsStorageProtocol { get }
}
