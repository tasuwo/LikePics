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
    private let clipViewer: ClipViewable
    private let finder = WebImageUrlFinder()
    private let currentDateResolver = { Date() }

    init() throws {
        let logger = RootLogger.shared
        let imageStorage = try ImageStorage(configuration: .temporary)
        let lightweightClipStorage = try LightweightClipStorage(config: .main, logger: logger)
        let clipStorage = try ClipStorage(config: .temporary, logger: logger)
        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage,
                                                     lightweightClipStorage: lightweightClipStorage,
                                                     imageStorage: imageStorage,
                                                     logger: logger)
        self.clipViewer = lightweightClipStorage
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
                                                  clipViewer: self.clipViewer,
                                                  finder: self.finder,
                                                  currentDateResolver: currentDateResolver)
        return ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
    }
}

extension TemporaryClipCommandService: ClipStorable {}
extension LightweightClipStorage: ClipViewable {}
