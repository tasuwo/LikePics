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
    func makeClipItemPreviewViewController(clipId: Clip.Identity, itemId: ClipItem.Identity) -> ClipItemPreviewViewController?

    // MARK: Information

    func makeClipInformationViewController(clipId: Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?

    // MARK: Selection

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController

    // MARK: Search

    func makeSearchEntryViewController() -> UIViewController
    func makeSearchResultViewController(context: SearchContext) -> UIViewController?

    // MARK: Album

    func makeAlbumListViewController() -> UIViewController?
    func makeAlbumViewController(albumId: Album.Identity) -> UIViewController?
    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController?

    // MARK: Tag

    func makeTagListViewController() -> UIViewController?
    func makeTagSelectionViewController(selectedTags: [Tag.Identity], context: Any?, delegate: TagSelectionPresenterDelegate) -> UIViewController?

    // MARK: Settings

    func makeSettingsViewController() -> UIViewController
}

class DependencyContainer {
    private let clipStorage: ClipStorage
    private let cacheStorage: ThumbnailStorageProtocol
    private lazy var logger = RootLogger.shared
    private lazy var userSettingsStorage = UserSettingsStorage()

    init() throws {
        let thumbnailStorage = try ThumbnailStorage()
        self.clipStorage = try ClipStorage(imageStorage: ImageStorage(),
                                           thumbnailStorage: thumbnailStorage)
        self.cacheStorage = thumbnailStorage
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipsListViewController() -> UIViewController? {
        let query: ClipListQuery
        switch self.clipStorage.queryAllClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TopClipsListView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TopClipsListPresenter(query: query,
                                              clipStorage: self.clipStorage,
                                              cacheStorage: self.cacheStorage,
                                              settingStorage: self.userSettingsStorage,
                                              logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .top, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        let viewController = TopClipsListViewController(factory: self,
                                                        presenter: presenter,
                                                        clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                                        navigationItemsProvider: navigationItemsProvider,
                                                        toolBarItemsProvider: toolBarItemsProvider)

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewViewController(clipId: Clip.Identity) -> UIViewController? {
        let query: ClipQuery
        switch self.clipStorage.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipPreviewView for clip having clip id \(clipId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipPreviewPagePresenter(query: query,
                                                 storage: self.clipStorage,
                                                 logger: self.logger)

        let barItemsPresenter = ClipPreviewPageBarButtonItemsPresenter(dataSource: presenter)
        let barItemsProvider = ClipPreviewPageBarButtonItemsProvider(presenter: barItemsPresenter)

        let previewTransitioningController = ClipPreviewTransitioningController(logger: self.logger)
        let informationTransitioningController = ClipInformationTransitioningController(logger: self.logger)

        let pageViewController = ClipPreviewPageViewController(
            factory: self,
            presenter: presenter,
            barItemsProvider: barItemsProvider,
            previewTransitioningController: previewTransitioningController,
            informationTransitionController: informationTransitioningController
        )

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = previewTransitioningController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(clipId: Clip.Identity, itemId: ClipItem.Identity) -> ClipItemPreviewViewController? {
        let query: ClipQuery
        switch self.clipStorage.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipItemPreviewView for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipItemPreviewPresenter(query: query,
                                                 itemId: itemId,
                                                 storage: self.clipStorage,
                                                 cacheStorage: self.cacheStorage,
                                                 logger: self.logger)

        let viewController = ClipItemPreviewViewController(factory: self, presenter: presenter)

        return viewController
    }

    func makeClipInformationViewController(clipId: Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?
    {
        let query: ClipQuery
        switch self.clipStorage.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationPresenter for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipInformationPresenter(query: query,
                                                 itemId: itemId,
                                                 storage: self.clipStorage,
                                                 logger: self.logger)

        let viewController = ClipInformationViewController(factory: self,
                                                           dataSource: dataSource,
                                                           presenter: presenter,
                                                           transitioningController: transitioningController)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController {
        let presenter = ClipTargetFinderPresenter(url: clipUrl,
                                                  clipStorage: self.clipStorage,
                                                  queryService: self.clipStorage,
                                                  finder: WebImageUrlFinder(),
                                                  currentDateResolver: { Date() },
                                                  isEnabledOverwrite: isOverwrite)
        let viewController = ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchEntryViewController() -> UIViewController {
        let presenter = SearchEntryPresenter(storage: self.clipStorage, logger: self.logger)
        let viewController = SearchEntryViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchResultViewController(context: SearchContext) -> UIViewController? {
        let query: ClipListQuery
        switch context {
        case let .keywords(values):
            switch self.clipStorage.queryClips(matchingKeywords: values) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for keywords \(values). (\(error.rawValue))
                """))
                return nil
            }

        case let .tag(value):
            switch self.clipStorage.queryClips(tagged: value) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for tag \(value). (\(error.rawValue))
                """))
                return nil
            }

        case .uncategorized:
            switch self.clipStorage.queryUncategorizedClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for uncategorized clips. (\(error.rawValue))
                """))
                return nil
            }
        }

        let presenter = SearchResultPresenter(context: context,
                                              query: query,
                                              clipStorage: self.clipStorage,
                                              cacheStorage: self.cacheStorage,
                                              settingStorage: self.userSettingsStorage,
                                              logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .searchResult, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return SearchResultViewController(factory: self,
                                          presenter: presenter,
                                          clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                          navigationItemsProvider: navigationItemsProvider,
                                          toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAlbumListViewController() -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipStorage.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumListView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumListPresenter(query: query,
                                           storage: self.clipStorage,
                                           cacheStorage: self.cacheStorage,
                                           settingStorage: self.userSettingsStorage,
                                           logger: self.logger)

        let viewController = AlbumListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(albumId: Album.Identity) -> UIViewController? {
        let query: AlbumQuery
        switch self.clipStorage.queryAlbum(having: albumId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumView for album having id \(albumId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumPresenter(query: query,
                                       clipStorage: self.clipStorage,
                                       cacheStorage: self.cacheStorage,
                                       settingStorage: self.userSettingsStorage,
                                       logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .album, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return AlbumViewController(factory: self,
                                   presenter: presenter,
                                   clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                   navigationItemsProvider: navigationItemsProvider,
                                   toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipStorage.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumSelectionPresenter(query: query,
                                                context: context,
                                                storage: self.clipStorage,
                                                cacheStorage: self.cacheStorage,
                                                settingStorage: self.userSettingsStorage,
                                                logger: self.logger)
        presenter.delegate = delegate
        let viewController = AlbumSelectionViewController(factory: self, presenter: presenter)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController? {
        let query: TagListQuery
        switch self.clipStorage.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TagListPresenter(query: query,
                                         storage: self.clipStorage,
                                         logger: self.logger)
        let viewController = TagListViewController(factory: self, presenter: presenter, logger: self.logger)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagSelectionViewController(selectedTags: [Tag.Identity],
                                        context: Any?,
                                        delegate: TagSelectionPresenterDelegate) -> UIViewController?
    {
        let query: TagListQuery
        switch self.clipStorage.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TagSelectionPresenter(query: query,
                                              selectedTags: selectedTags,
                                              context: context,
                                              storage: self.clipStorage,
                                              logger: self.logger)
        presenter.delegate = delegate
        let viewController = TagSelectionViewController(factory: self, presenter: presenter)
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