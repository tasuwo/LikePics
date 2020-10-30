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
    private let clipCommandService: ClipCommandServiceProtocol
    private let clipQueryService: ClipQueryServiceProtocol
    private lazy var finder = WebImageUrlFinder()
    private lazy var currentDateResolver = { Date() }

    init() throws {
        let thumbnailStorage = try ThumbnailStorage()
        let imageStorage = try ImageStorage()
        let lightweightClipStorage = try LightweightClipStorage(logger: RootLogger.shared)
        let clipStorage = try ClipStorage(logger: RootLogger.shared)
        self.clipCommandService = ClipCommandService(clipStorage: clipStorage,
                                                     lightweightClipStorage: lightweightClipStorage,
                                                     imageStorage: imageStorage,
                                                     thumbnailStorage: thumbnailStorage)
        self.clipQueryService = clipStorage
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
                                                  clipCommandService: self.clipCommandService,
                                                  clipQueryService: self.clipQueryService,
                                                  finder: self.finder,
                                                  currentDateResolver: currentDateResolver)
        return ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
    }
}
