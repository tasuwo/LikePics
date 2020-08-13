//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence

protocol ViewControllerFactory {
    func makeClipTargetCollectionViewController() -> ClipTargetCollectionViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
    private lazy var webImageResolver = WebImageResolver()
    private lazy var currentDateResolver = { Date() }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeClipTargetCollectionViewController() -> ClipTargetCollectionViewController {
        let presenter = ClipTargetCollectionViewPresenter(storage: self.clipsStorage,
                                                          resolver: self.webImageResolver,
                                                          currentDateResovler: currentDateResolver)
        return ClipTargetCollectionViewController(factory: self, presenter: presenter)
    }
}
