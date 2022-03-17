//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Environment
import LikePicsCore
import LikePicsUIKit
import Persistence
import Smoothie
import UIKit

class SceneDependencyContainer {
    weak var sceneResolver: SceneResolvable!
    let container: AppDependencyContaining

    // MARK: - Initializer

    init(sceneResolver: SceneResolvable,
         container: AppDependencyContaining)
    {
        self.sceneResolver = sceneResolver
        self.container = container
    }
}

extension SceneDependencyContainer: HasRouter {
    var router: Router { self }
}

extension SceneDependencyContainer: HasPasteboard {
    var pasteboard: Pasteboard { container.pasteboard }
}

extension SceneDependencyContainer: HasClipCommandService {
    var clipCommandService: ClipCommandServiceProtocol { container.clipCommandService }
}

extension SceneDependencyContainer: HasClipQueryService {
    var clipQueryService: ClipQueryServiceProtocol { container.clipQueryService }
}

extension SceneDependencyContainer: HasClipSearchSettingService {
    var clipSearchSettingService: Domain.ClipSearchSettingService { container.clipSearchSettingService }
}

extension SceneDependencyContainer: HasClipSearchHistoryService {
    var clipSearchHistoryService: Domain.ClipSearchHistoryService { container.clipSearchHistoryService }
}

extension SceneDependencyContainer: HasUserSettingStorage {
    var userSettingStorage: UserSettingsStorageProtocol { container.userSettingStorage }
}

extension SceneDependencyContainer: HasImageQueryService {
    var imageQueryService: ImageQueryServiceProtocol { container.imageQueryService }
}

extension SceneDependencyContainer: HasTransitionLock {
    var transitionLock: TransitionLock { container.transitionLock }
}

extension SceneDependencyContainer: HasCloudAvailabilityService {
    var cloudAvailabilityService: CloudAvailabilityServiceProtocol { container.cloudAvailabilityService }
}

extension SceneDependencyContainer: HasModalNotificationCenter {
    var modalNotificationCenter: ModalNotificationCenter { container.modalNotificationCenter }
}

extension SceneDependencyContainer: HasNop {}
