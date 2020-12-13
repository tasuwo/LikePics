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
    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController
}

class DependencyContainer {
    private let logger: TBoxLoggable
    private let clipStore: ClipStorable
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
                                        delegate: TagSelectionViewControllerDelegate) -> UIViewController
    {
        let vc = TagSelectionViewController(viewModel: TagSelectionViewModel(query: DummyQuery(),
                                                                             selectedTags: selectedTags,
                                                                             commandService: DummyCommandService(),
                                                                             logger: self.logger),
                                            delegate: delegate)
        return UINavigationController(rootViewController: vc)
    }
}

extension TemporaryClipCommandService: ClipStorable {}

// TODO: 正規の実装に切り替え
struct DummyQuery: TagListQuery {
    var tags: CurrentValueSubject<[Domain.Tag], Error> = .init([
        .init(id: UUID(), name: "hoge"),
        .init(id: UUID(), name: "fuga"),
        .init(id: UUID(), name: "piyo"),
    ])
}

// TODO: 正規の実装に切り替え
struct DummyCommandService: TagCommandServiceProtocol {
    func create(tagWithName name: String) -> Result<Void, TagCommandServiceError> {
        return .failure(.internalError)
    }
}
