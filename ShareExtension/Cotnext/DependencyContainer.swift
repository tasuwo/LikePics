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
    private let storage: ClipStorage
    private lazy var finder = WebImageUrlFinder()
    private lazy var currentDateResolver = { Date() }

    init() throws {
        let thumbnailStorage = try ThumbnailStorage()
        self.storage = try ClipStorage(imageStorage: try ImageStorage(),
                                       thumbnailStorage: thumbnailStorage)
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter(storage: self.storage)
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController {
        let presenter = ClipTargetFinderPresenter(url: url,
                                                  clipStorage: self.storage,
                                                  queryService: self.storage,
                                                  finder: self.finder,
                                                  currentDateResolver: currentDateResolver)
        return ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
    }
}
