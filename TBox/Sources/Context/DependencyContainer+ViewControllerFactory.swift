//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Smoothie
import TBoxCore
import TBoxUIKit
import UIKit

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipCollectionViewController() -> UIViewController? {
        let query: ClipListQuery
        switch self.clipQueryService.queryAllClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TopClipCollectionView. (\(error.rawValue))
            """))
            return nil
        }

        let composition = ClipCollectionModel(clipService: self.clipCommandService,
                                              imageQueryService: self.imageQueryService,
                                              logger: self.logger)
        let viewModel = TopClipCollectionViewModel(query: query,
                                                   composition: composition,
                                                   settingStorage: self.userSettingsStorage,
                                                   logger: self.logger)

        let context = ClipCollection.Context(isAlbum: false)

        let navigationItemsViewModel = ClipCollectionNavigationBarViewModel(context: context)
        let navigationItemsProvider = ClipCollectionNavigationBarProvider(viewModel: navigationItemsViewModel)

        let toolBarItemsViewModel = ClipCollectionToolBarViewModel(context: context)
        let toolBarItemsProvider = ClipCollectionToolBarProvider(viewModel: toolBarItemsViewModel)

        let viewController = TopClipCollectionViewController(factory: self,
                                                             viewModel: viewModel,
                                                             clipCollectionProvider: ClipCollectionProvider(thumbnailLoader: self.clipThumbnailLoader),
                                                             navigationItemsProvider: navigationItemsProvider,
                                                             toolBarItemsProvider: toolBarItemsProvider,
                                                             menuBuilder: ClipCollectionMenuBuilder.self)

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewViewController(clipId: Domain.Clip.Identity) -> UIViewController? {
        let query: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipPreviewView for clip having clip id \(clipId). (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = ClipPreviewPageViewModel(clipId: clipId,
                                                 query: query,
                                                 clipCommandService: self.clipCommandService,
                                                 imageQueryService: self.imageQueryService,
                                                 logger: self.logger)

        let barItemsViewModel = ClipPreviewPageBarViewModel()
        let barItemsProvider = ClipPreviewPageBarViewController(viewModel: barItemsViewModel)

        let previewTransitioningController = ClipPreviewTransitioningController(logger: self.logger)
        let informationTransitionController = ClipInformationTransitioningController(logger: self.logger)
        let builder = { (factory: ClipPreviewPageTransitionController.Factory, viewController: UIViewController) in
            ClipPreviewPageTransitionController(factory: factory,
                                                baseViewController: viewController,
                                                previewTransitioningController: previewTransitioningController,
                                                informationTransitionController: informationTransitionController)
        }

        let pageViewController = ClipPreviewPageViewController(
            factory: self,
            viewModel: viewModel,
            barItemsProvider: barItemsProvider,
            transitionControllerBuilder: builder
        )

        let viewController = ClipPreviewBaseViewController(clipId: clipId, pageViewController: pageViewController)
        viewController.transitioningDelegate = previewTransitioningController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(itemId: ClipItem.Identity) -> ClipPreviewViewController? {
        let query: ClipItemQuery
        switch self.clipQueryService.queryClipItem(having: itemId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipItemPreviewView for clip. \(error.localizedDescription)
            """))
            return nil
        }

        let viewModel = ClipPreviewViewModel(query: query,
                                             imageQueryService: self.imageQueryService,
                                             logger: self.logger)
        let viewController = ClipPreviewViewController(factory: self, viewModel: viewModel)

        return viewController
    }

    func makeClipInformationViewController(clipId: Domain.Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?
    {
        let clipQuery: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            clipQuery = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationViewModel for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let itemQuery: ClipItemQuery
        switch self.clipQueryService.queryClipItem(having: itemId) {
        case let .success(result):
            itemQuery = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationViewModel for clipItem having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = ClipInformationViewModel(itemId: itemId,
                                                 clipQuery: clipQuery,
                                                 itemQuery: itemQuery,
                                                 clipCommandService: self.clipCommandService,
                                                 logger: self.logger)

        let viewController = ClipInformationViewController(factory: self,
                                                           dataSource: dataSource,
                                                           viewModel: viewModel,
                                                           transitioningController: transitioningController)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }

    func makeSearchEntryViewController() -> UIViewController {
        let presenter = SearchEntryPresenter()
        let viewController = SearchEntryViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchResultViewController(context: ClipCollection.SearchContext) -> UIViewController? {
        let query: ClipListQuery
        switch context {
        case let .keywords(values):
            switch self.clipQueryService.queryClips(matchingKeywords: values) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for keywords \(values). (\(error.rawValue))
                """))
                return nil
            }

        case let .tag(.categorized(value)):
            switch self.clipQueryService.queryClips(tagged: value) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for tag \(value). (\(error.rawValue))
                """))
                return nil
            }

        case .tag(.uncategorized):
            switch self.clipQueryService.queryUncategorizedClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for uncategorized clips. (\(error.rawValue))
                """))
                return nil
            }
        }

        let composition = ClipCollectionModel(clipService: self.clipCommandService,
                                              imageQueryService: self.imageQueryService,
                                              logger: self.logger)
        let viewModel = SearchResultViewModel(context: context,
                                              query: query,
                                              composition: composition,
                                              settingStorage: self.userSettingsStorage,
                                              logger: self.logger)

        let context = ClipCollection.Context(isAlbum: false)

        let navigationItemsViewModel = ClipCollectionNavigationBarViewModel(context: context)
        let navigationItemsProvider = ClipCollectionNavigationBarProvider(viewModel: navigationItemsViewModel)

        let toolBarItemsViewModel = ClipCollectionToolBarViewModel(context: context)
        let toolBarItemsProvider = ClipCollectionToolBarProvider(viewModel: toolBarItemsViewModel)

        return SearchResultViewController(factory: self,
                                          viewModel: viewModel,
                                          clipCollectionProvider: ClipCollectionProvider(thumbnailLoader: self.clipThumbnailLoader),
                                          navigationItemsProvider: navigationItemsProvider,
                                          toolBarItemsProvider: toolBarItemsProvider,
                                          menuBuilder: ClipCollectionMenuBuilder.self)
    }

    func makeAlbumListViewController() -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumListView. (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = AlbumListViewModel(query: query,
                                           clipCommandService: self.clipCommandService,
                                           settingStorage: self.userSettingsStorage,
                                           logger: self.logger)
        let viewController = AlbumListViewController(factory: self,
                                                     viewModel: viewModel,
                                                     thumbnailLoader: self.albumThumbnailLoader)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(albumId: Domain.Album.Identity) -> UIViewController? {
        let query: AlbumQuery
        switch self.clipQueryService.queryAlbum(having: albumId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumView for album having id \(albumId). (\(error.rawValue))
            """))
            return nil
        }

        let composition = ClipCollectionModel(clipService: self.clipCommandService,
                                              imageQueryService: self.imageQueryService,
                                              logger: self.logger)
        let viewModel = AlbumViewModel(query: query,
                                       composition: composition,
                                       clipService: self.clipCommandService,
                                       settingStorage: self.userSettingsStorage,
                                       logger: self.logger)

        let context = ClipCollection.Context(isAlbum: true)

        let navigationItemsViewModel = ClipCollectionNavigationBarViewModel(context: context)
        let navigationItemsProvider = ClipCollectionNavigationBarProvider(viewModel: navigationItemsViewModel)

        let toolBarItemsViewModel = ClipCollectionToolBarViewModel(context: context)
        let toolBarItemsProvider = ClipCollectionToolBarProvider(viewModel: toolBarItemsViewModel)

        return AlbumViewController(factory: self,
                                   viewModel: viewModel,
                                   clipCollectionProvider: ClipCollectionProvider(thumbnailLoader: self.clipThumbnailLoader),
                                   navigationItemsProvider: navigationItemsProvider,
                                   toolBarItemsProvider: toolBarItemsProvider,
                                   menuBuilder: ClipCollectionMenuBuilder.self)
    }

    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipQueryService.queryAllAlbums() {
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
                                                clipCommandService: self.clipCommandService,
                                                settingStorage: self.userSettingsStorage,
                                                logger: self.logger)
        presenter.delegate = delegate
        let viewController = AlbumSelectionViewController(factory: self,
                                                          presenter: presenter,
                                                          thumbnailLoader: self.temporaryThumbnailLoader)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController? {
        let query: TagListQuery
        switch self.clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = TagCollectionViewModel(query: query,
                                               clipCommandService: self.clipCommandService,
                                               logger: self.logger)
        let viewController = TagCollectionViewController(factory: self, viewModel: viewModel, logger: self.logger)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagSelectionViewController(selectedTags: [Domain.Tag.Identity],
                                        context: Any?,
                                        delegate: TagSelectionPresenterDelegate) -> UIViewController?
    {
        let query: TagListQuery
        switch self.clipQueryService.queryAllTags() {
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
                                              clipCommandService: self.clipCommandService,
                                              logger: self.logger)
        presenter.delegate = delegate
        let viewController = TagSelectionViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeMergeViewController(clips: [Clip], delegate: ClipMergeViewControllerDelegate) -> UIViewController {
        let viewModel = ClipMergeViewModel(clips: clips,
                                           commandService: self.clipCommandService,
                                           logger: self.logger)
        let viewController = ClipMergeViewController(factory: self,
                                                     viewModel: viewModel,
                                                     thumbnailLoader: self.temporaryThumbnailLoader)
        viewController.delegate = delegate
        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let presenter = SettingsPresenter(storage: self.userSettingsStorage,
                                          availabilityStore: self.cloudAvailabilityObserver)
        viewController.factory = self
        viewController.presenter = presenter

        return viewController
    }
}
