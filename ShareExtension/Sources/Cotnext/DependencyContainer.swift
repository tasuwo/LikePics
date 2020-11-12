//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Persistence
import TBoxCore

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController
}

class DependencyContainer {
    private let clipStore: ClipStorable
    private let currentDateResolver = { Date() }

    init() throws {
        let logger = RootLogger.shared
        let imageStorage = try ImageStorage(configuration: .group)
        let referenceClipStorage = try ReferenceClipStorage(config: .group, logger: logger)
        let clipStorage = try ClipStorage(config: .group, logger: logger)
        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage,
                                                     referenceClipStorage: referenceClipStorage,
                                                     imageStorage: imageStorage,
                                                     logger: logger)
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter()
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController {
        let presenter = ClipTargetFinderPresenter(url: url,
                                                  clipStore: self.clipStore,
                                                  currentDateResolver: currentDateResolver)
        return ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
    }
}

extension TemporaryClipCommandService: ClipStorable {}
