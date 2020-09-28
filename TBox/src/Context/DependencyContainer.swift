//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Persistence
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    // MARK: Top

    func makeTopClipsListViewController() -> UIViewController?

    // MARK: Preview

    func makeClipPreviewViewController(clipId: Clip.Identity) -> UIViewController?
    func makeClipItemPreviewViewController(clip: Clip, item: ClipItem) -> ClipItemPreviewViewController

    // MARK: Information

    func makeClipInformationViewController(clip: Clip, item: ClipItem, dataSource: ClipInformationViewDataSource) -> UIViewController

    // MARK: Selection

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController

    // MARK: Search

    func makeSearchEntryViewController() -> UIViewController
    func makeSearchResultViewController(context: SearchContext) -> UIViewController?

    // MARK: Album

    func makeAlbumListViewController() -> UIViewController
    func makeAlbumViewController(albumId: Album.Identity) -> UIViewController?
    func makeAddingClipsToAlbumViewController(clips: [Clip], delegate: AddingClipsToAlbumPresenterDelegate?) -> UIViewController

    // MARK: Tag

    func makeTagListViewController() -> UIViewController
    func makeAddingTagToClipViewController(clips: [Clip], delegate: AddingTagsToClipsPresenterDelegate?) -> UIViewController

    // MARK: Settings

    func makeSettingsViewController() -> UIViewController
}

class DependencyContainer {
    private let clipStorage: ClipStorage
    private lazy var logger = RootLogger.shared
    private lazy var userSettingsStorage = UserSettingsStorage()
    private lazy var clipPreviewTransitionController = ClipPreviewTransitioningController()
    private lazy var clipInformationTransitionController = ClipInformationTransitioningController()

    init() throws {
        self.clipStorage = try ClipStorage()
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipsListViewController() -> UIViewController? {
        guard let presenter = NewTopClipsListPresenter(clipStorage: self.clipStorage,
                                                       settingStorage: self.userSettingsStorage,
                                                       queryService: self.clipStorage,
                                                       logger: self.logger)
        else {
            return nil
        }

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .top, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        let viewController = NewTopClipsListViewController(factory: self,
                                                           presenter: presenter,
                                                           navigationItemsProvider: navigationItemsProvider,
                                                           toolBarItemsProvider: toolBarItemsProvider)

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewViewController(clipId: Clip.Identity) -> UIViewController? {
        guard let presenter = ClipPreviewPagePresenter(clipId: clipId,
                                                       storage: self.clipStorage,
                                                       queryService: self.clipStorage,
                                                       logger: self.logger)
        else {
            return nil
        }

        let barItemsPresenter = ClipPreviewPageBarButtonItemsPresenter(dataSource: presenter)
        let barItemsProvider = ClipPreviewPageBarButtonItemsProvider(presenter: barItemsPresenter)

        let pageViewController = ClipPreviewPageViewController(factory: self,
                                                               presenter: presenter,
                                                               barItemsProvider: barItemsProvider,
                                                               previewTransitionController: self.clipPreviewTransitionController,
                                                               informationTransitionController: self.clipInformationTransitionController)

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = self.clipPreviewTransitionController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(clip: Clip, item: ClipItem) -> ClipItemPreviewViewController {
        let presenter = ClipItemPreviewPresenter(clip: clip, item: item, storage: self.clipStorage, logger: self.logger)
        let viewController = ClipItemPreviewViewController(factory: self, presenter: presenter)
        return viewController
    }

    func makeClipInformationViewController(clip: Clip, item: ClipItem, dataSource: ClipInformationViewDataSource) -> UIViewController {
        let presenter = ClipInformationPresenter(clip: clip, item: item)
        let viewController = ClipInformationViewController(factory: self, dataSource: dataSource, presenter: presenter, transitionController: self.clipInformationTransitionController)
        viewController.transitioningDelegate = self.clipInformationTransitionController
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController {
        let presenter = ClipTargetFinderPresenter(url: clipUrl,
                                                  storage: self.clipStorage,
                                                  finder: WebImageUrlFinder(),
                                                  currentDateResovler: { Date() },
                                                  isEnabledOverwrite: isOverwrite)
        let viewController = ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchEntryViewController() -> UIViewController {
        let presenter = SearchEntryPresenter(storage: self.clipStorage, logger: self.logger)
        return UINavigationController(rootViewController: SearchEntryViewController(factory: self, presenter: presenter, transitionController: self.clipPreviewTransitionController))
    }

    func makeSearchResultViewController(context: SearchContext) -> UIViewController? {
        guard let presenter = SearchResultPresenter(context: context,
                                                    clipStorage: self.clipStorage,
                                                    settingStorage: self.userSettingsStorage,
                                                    queryService: self.clipStorage,
                                                    logger: self.logger)
        else {
            return nil
        }

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .searchResult, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return SearchResultViewController(factory: self,
                                          presenter: presenter,
                                          navigationItemsProvider: navigationItemsProvider,
                                          toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAlbumListViewController() -> UIViewController {
        let presenter = AlbumListPresenter(storage: self.clipStorage, queryService: self.clipStorage, logger: self.logger)
        let viewController = AlbumListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(albumId: Album.Identity) -> UIViewController? {
        guard let presenter = AlbumPresenter(albumId: albumId,
                                             clipStorage: self.clipStorage,
                                             settingStorage: self.userSettingsStorage,
                                             queryService: self.clipStorage,
                                             logger: self.logger)
        else {
            return nil
        }

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .album, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return AlbumViewController(factory: self,
                                   presenter: presenter,
                                   navigationItemsProvider: navigationItemsProvider,
                                   toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAddingClipsToAlbumViewController(clips: [Clip], delegate: AddingClipsToAlbumPresenterDelegate?) -> UIViewController {
        let presenter = AddingClipsToAlbumPresenter(sourceClips: clips, storage: self.clipStorage, logger: self.logger)
        presenter.delegate = delegate
        let viewController = AddingClipsToAlbumViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController {
        let presenter = TagListPresenter(storage: self.clipStorage, queryService: self.clipStorage, logger: self.logger)
        let viewController = TagListViewController(factory: self, presenter: presenter, logger: self.logger)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAddingTagToClipViewController(clips: [Clip], delegate: AddingTagsToClipsPresenterDelegate?) -> UIViewController {
        let presenter = AddingTagsToClipsPresenter(clips: clips, storage: self.clipStorage)
        presenter.delegate = delegate
        let viewController = AddingTagsToClipsViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let presenter = SettingsPresenter(storage: self.userSettingsStorage)
        viewController.factory = self
        viewController.presenter = presenter

        return viewController
    }
}
