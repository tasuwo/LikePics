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
        let mainBundleUrl = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        guard let mainBundle = Bundle(url: mainBundleUrl) else {
            fatalError("Failed to resolve main bundle.")
        }

        let logger = RootLogger.shared
        let imageStorage = try ImageStorage(configuration: .resolve(for: mainBundle, kind: .group))
        let clipStorage = try ClipStorage(config: .resolve(for: mainBundle, kind: .group),
                                          logger: logger)
        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage,
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
        let viewModel = ClipTargetFinderViewModel(url: url, clipStore: self.clipStore)
        return ClipTargetFinderViewController(viewModel: viewModel, delegate: delegate)
    }
}

extension TemporaryClipCommandService: ClipStorable {}
