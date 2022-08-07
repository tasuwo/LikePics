//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeature
import Common
import CoreData
import Domain
import Environment
import LikePicsUIKit
import Persistence
import Smoothie
import UIKit

public class SceneDependencyContainer {
    weak var sceneResolver: SceneResolvable!
    public let container: AppDependencyContaining

    // MARK: - Initializer

    public init(sceneResolver: SceneResolvable,
                container: AppDependencyContaining)
    {
        self.sceneResolver = sceneResolver
        self.container = container
    }
}

extension SceneDependencyContainer: HasRouter {
    public var router: Router { self }
}

extension SceneDependencyContainer: HasPasteboard {
    public var pasteboard: Pasteboard { container.pasteboard }
}

extension SceneDependencyContainer: HasClipCommandService {
    public var clipCommandService: ClipCommandServiceProtocol { container.clipCommandService }
}

extension SceneDependencyContainer: HasClipQueryService {
    public var clipQueryService: ClipQueryServiceProtocol { container.clipQueryService }
}

extension SceneDependencyContainer: HasClipSearchSettingService {
    public var clipSearchSettingService: Domain.ClipSearchSettingService { container.clipSearchSettingService }
}

extension SceneDependencyContainer: HasClipSearchHistoryService {
    public var clipSearchHistoryService: Domain.ClipSearchHistoryService { container.clipSearchHistoryService }
}

extension SceneDependencyContainer: HasUserSettingStorage {
    public var userSettingStorage: UserSettingsStorageProtocol { container.userSettingStorage }
}

extension SceneDependencyContainer: HasImageQueryService {
    public var imageQueryService: ImageQueryServiceProtocol { container.imageQueryService }
}

extension SceneDependencyContainer: HasTransitionLock {
    public var transitionLock: TransitionLock { container.transitionLock }
}

extension SceneDependencyContainer: HasCloudAvailabilityService {
    public var cloudAvailabilityService: CloudAvailabilityServiceProtocol { container.cloudAvailabilityService }
}

extension SceneDependencyContainer: HasModalNotificationCenter {
    public var modalNotificationCenter: ModalNotificationCenter { container.modalNotificationCenter }
}

extension SceneDependencyContainer: HasNop {}

extension SceneDependencyContainer: HasDiskCaches {
    public var clipDiskCache: DiskCaching { container.clipDiskCache }
    public var albumDiskCache: DiskCaching { container.albumDiskCache }
    public var clipItemDiskCache: DiskCaching { container.clipDiskCache }
}

extension SceneDependencyContainer: HasAppBundle {
    public var appBundle: Bundle { container.appBundle }
}

extension SceneDependencyContainer: HasTagCommandService {
    public var tagCommandService: TagCommandServiceProtocol { container.tagCommandService }
}

extension SceneDependencyContainer: HasTagQueryService {
    public var tagQueryService: TagQueryServiceProtocol { container.tagQueryService }
}
