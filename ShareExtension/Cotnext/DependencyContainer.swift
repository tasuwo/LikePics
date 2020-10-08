//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import TBoxCore

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController
}

class DependencyContainer {
    // TODO: Error Handling
    private lazy var storage = try! ClipStorage()
    private lazy var finder = WebImageUrlFinder()
    private lazy var currentDateResolver = { Date() }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter(storage: self.storage)
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController {
        let presenter = ClipTargetFinderPresenter(url: url,
                                                  storage: self.storage,
                                                  finder: self.finder,
                                                  currentDateResolver: currentDateResolver)
        return ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
    }
}
