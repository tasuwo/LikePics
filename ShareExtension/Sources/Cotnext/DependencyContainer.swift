//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Persistence
import TBoxCore
import UIKit

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(url: URL, delegate: ClipCreationDelegate) -> ClipCreationViewController
    func makeClipTargetCollectionViewController(data: [Data], delegate: ClipCreationDelegate) -> ClipCreationViewController
}

class DependencyContainer {
    private let logger: TBoxLoggable
    private let clipStore: ClipStorable
    private let tagQueryService: ReferenceTagQueryService
    private let currentDateResolver = { Date() }
    private let tagCommandService: TagCommandService
    private let userSettingsStorage: UserSettingsStorage

    init() throws {
        let mainBundleUrl = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        guard let mainBundle = Bundle(url: mainBundleUrl) else {
            fatalError("Failed to resolve main bundle.")
        }

        self.logger = RootLogger.shared
        let imageStorage = try ImageStorage(configuration: .resolve(for: mainBundle, kind: .group))
        let clipStorage = try ClipStorage(config: .resolve(for: mainBundle, kind: .group),
                                          logger: self.logger)
        let referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: mainBundle),
                                                            logger: self.logger)

        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage,
                                                     imageStorage: imageStorage,
                                                     logger: self.logger)

        self.tagQueryService = try ReferenceTagQueryService(config: .resolve(for: mainBundle),
                                                            logger: self.logger)

        self.tagCommandService = TagCommandService(storage: referenceClipStorage,
                                                   logger: self.logger)

        self.userSettingsStorage = UserSettingsStorage(bundle: mainBundle)
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter()
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL, delegate: ClipCreationDelegate) -> ClipCreationViewController {
        return ClipCreationViewController(factory: self,
                                          viewModel: ClipCreationViewModel(url: url,
                                                                           clipStore: self.clipStore,
                                                                           provider: WebImageSourceProvider(url: url)),
                                          delegate: delegate)
    }

    func makeClipTargetCollectionViewController(data: [Data], delegate: ClipCreationDelegate) -> ClipCreationViewController {
        return ClipCreationViewController(factory: self,
                                          viewModel: ClipCreationViewModel(url: nil,
                                                                           clipStore: self.clipStore,
                                                                           provider: RawImageSourceProvider(imageDataSet: data)),
                                          delegate: delegate)
    }
}

extension DependencyContainer: TBoxCore.ViewControllerFactory {
    func makeTagSelectionViewController(selectedTags: Set<Domain.Tag.Identity>,
                                        delegate: TagSelectionViewControllerDelegate) -> UIViewController?
    {
        switch self.tagQueryService.queryTags() {
        case let .success(query):
            let viewModel = TagSelectionViewModel(query: query,
                                                  selectedTags: selectedTags,
                                                  commandService: self.tagCommandService,
                                                  settingStorage: self.userSettingsStorage,
                                                  logger: self.logger)
            let viewController = TagSelectionViewController(viewModel: viewModel, delegate: delegate)
            return UINavigationController(rootViewController: viewController)

        case .failure:
            return nil
        }
    }
}

extension TemporaryClipCommandService: ClipStorable {}
