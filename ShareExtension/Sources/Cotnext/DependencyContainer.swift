//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Persistence
import TBoxCore
import UIKit

// TODO: 正規の実装に切り替え
struct DummyCommandService: TagCommandServiceProtocol {
    func create(tagWithName name: String) -> Result<Void, TagCommandServiceError> {
        return .failure(.internalError)
    }
}

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController
}

class DependencyContainer {
    private let logger: TBoxLoggable
    private let clipStore: ClipStorable
    private let tagQueryService: ReferenceTagQueryService
    private let currentDateResolver = { Date() }

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
        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage,
                                                     imageStorage: imageStorage,
                                                     logger: self.logger)

        self.tagQueryService = try ReferenceTagQueryService(config: .resolve(for: mainBundle),
                                                            logger: self.logger)
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter()
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController {
        return ClipTargetFinderViewController(factory: self,
                                              viewModel: ClipTargetFinderViewModel(url: url, clipStore: self.clipStore),
                                              tagsViewModel: ClipTargetFinderSelectedTagsViewModel(),
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
                                                  commandService: DummyCommandService(),
                                                  logger: self.logger)
            let viewController = TagSelectionViewController(viewModel: viewModel, delegate: delegate)
            return UINavigationController(rootViewController: viewController)

        case .failure:
            return nil
        }
    }
}

extension TemporaryClipCommandService: ClipStorable {}
