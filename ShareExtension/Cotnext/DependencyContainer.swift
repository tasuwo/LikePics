//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(url: URL) -> ClipTargetCollectionViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
    private lazy var webImageResolver = WebImageResolver()
    private lazy var currentDateResolver = { Date() }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter(storage: self.clipsStorage)
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL) -> ClipTargetCollectionViewController {
        let presenter = ClipTargetCollectionViewPresenter(url: url,
                                                          storage: self.clipsStorage,
                                                          resolver: self.webImageResolver,
                                                          currentDateResovler: currentDateResolver)
        return ClipTargetCollectionViewController(factory: self, presenter: presenter)
    }
}
