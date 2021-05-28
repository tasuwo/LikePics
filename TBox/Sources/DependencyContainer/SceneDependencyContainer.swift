//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Persistence
import Smoothie
import TBoxCore
import TBoxUIKit
import UIKit

class SceneDependencyContainer {
    weak var sceneResolver: SceneResolvable!
    let container: DependencyContainer

    // MARK: - Initializer

    init(sceneResolver: SceneResolvable,
         container: DependencyContainer)
    {
        self.sceneResolver = sceneResolver
        self.container = container
    }
}

extension SceneDependencyContainer: HasRouter {
    var router: Router { self }
}

extension SceneDependencyContainer: HasPasteboard {
    var pasteboard: Pasteboard { UIPasteboard.general }
}

extension SceneDependencyContainer: HasClipCommandService {
    var clipCommandService: ClipCommandServiceProtocol { container._clipCommandService }
}

extension SceneDependencyContainer: HasClipQueryService {
    var clipQueryService: ClipQueryServiceProtocol { container._clipQueryService }
}

extension SceneDependencyContainer: HasClipSearchSettingService {
    var clipSearchSettingService: Domain.ClipSearchSettingService { container._clipSearchSettingService }
}

extension SceneDependencyContainer: HasClipSearchHistoryService {
    var clipSearchHistoryService: Domain.ClipSearchHistoryService { container._clipSearchHistoryService }
}

extension SceneDependencyContainer: HasUserSettingStorage {
    var userSettingStorage: UserSettingsStorageProtocol { container._userSettingStorage }
}

extension SceneDependencyContainer: HasImageQueryService {
    var imageQueryService: ImageQueryServiceProtocol { container._imageQueryService }
}

extension SceneDependencyContainer: HasPreviewLoader {
    var previewLoader: PreviewLoader { container._previewLoader }
}

extension SceneDependencyContainer: HasTransitionLock {
    var transitionLock: TransitionLock { container.transitionLock }
}

extension SceneDependencyContainer: HasCloudAvailabilityService {
    var cloudAvailabilityService: CloudAvailabilityServiceProtocol { container._cloudAvailabilityService }
}

extension SceneDependencyContainer: HasModalNotificationCenter {
    var modalNotificationCenter: ModalNotificationCenter { ModalNotificationCenter.default }
}

extension SceneDependencyContainer: HasNop {}
