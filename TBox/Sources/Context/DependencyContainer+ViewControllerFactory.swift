//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
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
        switch self._clipQueryService.queryAllClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TopClipCollectionView. (\(error.rawValue))
            """))
            return nil
        }

        let innerViewModel = ClipCollectionViewModel(clipService: self._clipCommandService,
                                                     queryService: self._clipQueryService,
                                                     imageQueryService: self.imageQueryService,
                                                     logger: self.logger)
        let viewModel = TopClipCollectionViewModel(query: query,
                                                   settingStorage: self._userSettingStorage,
                                                   logger: self.logger,
                                                   viewModel: innerViewModel)

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
                                                             menuBuilder: ClipCollectionMenuBuilder(storage: self._userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewPageViewController(clipId: Domain.Clip.Identity) -> UIViewController? {
        let clipQuery: ClipQuery
        switch self._clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            clipQuery = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipPreviewView for clip having clip id \(clipId). (\(error.rawValue))
            """))
            return nil
        }

        let tagListQuery: TagListQuery
        switch self._clipQueryService.queryTags(forClipHaving: clipId) {
        case let .success(result):
            tagListQuery = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipPreviewView for clip having clip id \(clipId). (\(error.rawValue))
            """))
            return nil
        }

        guard let viewModel = ClipPreviewPageViewModel(clipId: clipId,
                                                       clipQuery: clipQuery,
                                                       tagListQuery: tagListQuery,
                                                       clipCommandService: self._clipCommandService,
                                                       previewLoader: self.previewLoader,
                                                       imageQueryService: self.imageQueryService,
                                                       logger: self.logger)
        else {
            return nil
        }

        let preLoadViewModel = PreLoadingClipInformationViewModel(clipQueryService: _clipQueryService,
                                                                  settingStorage: _userSettingStorage)
        let preLoadViewController = PreLoadingClipInformationViewController(clipId: clipId,
                                                                            preLoadViewModel: preLoadViewModel)

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
            preLoadViewController: preLoadViewController,
            barItemsProvider: barItemsProvider,
            transitionControllerBuilder: builder
        )

        let viewController = ClipPreviewBaseViewController(clipId: clipId, pageViewController: pageViewController)
        viewController.transitioningDelegate = previewTransitioningController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipPreviewViewController(itemId: ClipItem.Identity, usesImageForPresentingAnimation: Bool) -> ClipPreviewViewController? {
        let query: ClipItemQuery
        switch self._clipQueryService.queryClipItem(having: itemId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipItemPreviewView for clip. \(error.localizedDescription)
            """))
            return nil
        }

        let viewModel = ClipPreviewViewModel(query: query,
                                             previewLoader: self.previewLoader,
                                             usesImageForPresentingAnimation: usesImageForPresentingAnimation,
                                             logger: self.logger)
        let viewController = ClipPreviewViewController(factory: self, viewModel: viewModel)

        return viewController
    }

    func makeClipInformationViewController(clipId: Domain.Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           informationView: ClipInformationView,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?
    {
        let clipQuery: ClipQuery
        switch self._clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            clipQuery = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationViewModel for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let itemQuery: ClipItemQuery
        switch self._clipQueryService.queryClipItem(having: itemId) {
        case let .success(result):
            itemQuery = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationViewModel for clipItem having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let tagListQuery: TagListQuery
        switch self._clipQueryService.queryTags(forClipHaving: clipId) {
        case let .success(result):
            tagListQuery = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationViewModel for clip having clip id \(clipId). (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = ClipInformationViewModel(itemId: itemId,
                                                 clipQuery: clipQuery,
                                                 itemQuery: itemQuery,
                                                 tagListQuery: tagListQuery,
                                                 clipCommandService: self._clipCommandService,
                                                 settingStorage: self._userSettingStorage,
                                                 logger: self.logger)

        let viewController = ClipInformationViewController(factory: self,
                                                           dataSource: dataSource,
                                                           viewModel: viewModel,
                                                           informationView: informationView,
                                                           transitioningController: transitioningController)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }

    func makeClipEditViewController(clipId: Clip.Identity) -> UIViewController? {
        guard let viewModel = ClipEditViewModel(id: clipId,
                                                clipQueryService: self._clipQueryService,
                                                clipCommandService: self._clipCommandService,
                                                settingStorage: self._userSettingStorage,
                                                logger: self.logger)
        else {
            return nil
        }
        let viewController = ClipEditViewController(factory: self,
                                                    viewModel: viewModel,
                                                    thumbnailLoader: self.temporaryThumbnailLoader)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchEntryViewController() -> UIViewController {
        let viewModel = SearchEntryViewModel()
        let viewController = SearchEntryViewController(factory: self, viewModel: viewModel)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchResultViewController(context: ClipCollection.SearchContext) -> UIViewController? {
        let query: ClipListQuery
        switch context {
        case let .keywords(values):
            switch self._clipQueryService.queryClips(matchingKeywords: values) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for keywords \(values). (\(error.rawValue))
                """))
                return nil
            }

        case let .tag(.categorized(value)):
            switch self._clipQueryService.queryClips(tagged: value) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for tag \(value). (\(error.rawValue))
                """))
                return nil
            }

        case .tag(.uncategorized):
            switch self._clipQueryService.queryUncategorizedClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for uncategorized clips. (\(error.rawValue))
                """))
                return nil
            }
        }

        let innerViewModel = ClipCollectionViewModel(clipService: self._clipCommandService,
                                                     queryService: self._clipQueryService,
                                                     imageQueryService: self.imageQueryService,
                                                     logger: self.logger)
        let viewModel = SearchResultViewModel(context: context,
                                              query: query,
                                              settingStorage: self._userSettingStorage,
                                              logger: self.logger,
                                              viewModel: innerViewModel)

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
                                          menuBuilder: ClipCollectionMenuBuilder(storage: self._userSettingStorage))
    }

    func makeAlbumListViewController() -> UIViewController? {
        let query: AlbumListQuery
        switch self._clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumListView. (\(error.rawValue))
            """))
            return nil
        }

        let navBarViewModel = AlbumListNavigationBarViewModel()
        let navBarProvider = AlbumListNavigationBarProvider(viewModel: navBarViewModel)

        let viewModel = AlbumListViewModel(query: query,
                                           clipCommandService: self._clipCommandService,
                                           settingStorage: self._userSettingStorage,
                                           logger: self.logger)
        let viewController = AlbumListViewController(factory: self,
                                                     viewModel: viewModel,
                                                     navigationBarProvider: navBarProvider,
                                                     menuBuilder: AlbumListMenuBuilder.self,
                                                     thumbnailLoader: self.albumThumbnailLoader)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(albumId: Domain.Album.Identity) -> UIViewController? {
        let query: AlbumQuery
        switch self._clipQueryService.queryAlbum(having: albumId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumView for album having id \(albumId). (\(error.rawValue))
            """))
            return nil
        }

        let innerViewModel = ClipCollectionViewModel(clipService: self._clipCommandService,
                                                     queryService: self._clipQueryService,
                                                     imageQueryService: self.imageQueryService,
                                                     logger: self.logger)
        let viewModel = AlbumViewModel(query: query,
                                       clipService: self._clipCommandService,
                                       settingStorage: self._userSettingStorage,
                                       logger: self.logger,
                                       viewModel: innerViewModel)

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
                                   menuBuilder: ClipCollectionMenuBuilder(storage: self._userSettingStorage))
    }

    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController? {
        let query: AlbumListQuery
        switch self._clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = AlbumSelectionViewModel(query: query,
                                                context: context,
                                                clipCommandService: self._clipCommandService,
                                                settingStorage: self._userSettingStorage,
                                                logger: self.logger)
        viewModel.delegate = delegate
        let viewController = AlbumSelectionViewController(factory: self,
                                                          viewModel: viewModel,
                                                          thumbnailLoader: self.temporaryThumbnailLoader)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController? {
        let query: TagListQuery
        switch self._clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = TagCollectionViewModel(query: query,
                                               clipCommandService: self._clipCommandService,
                                               settingStorage: self._userSettingStorage,
                                               logger: self.logger)
        let viewController = TagCollectionViewController(factory: self,
                                                         viewModel: viewModel,
                                                         menuBuilder: TagCollectionMenuBuilder(storage: self._userSettingStorage),
                                                         logger: self.logger)

        return UINavigationController(rootViewController: viewController)
    }

    func makeNewTagListViewController() -> UIViewController? {
        let state = TagCollectionViewState(items: [],
                                           searchQuery: "",
                                           isSomeItemsHidden: _userSettingStorage.readShowHiddenItems(),
                                           isCollectionViewDisplaying: false,
                                           isEmptyMessageViewDisplaying: false,
                                           isSearchBarEnabled: false,
                                           alert: nil,
                                           _tags: [],
                                           _searchStorage: .init())
        let tagAdditionAlertState = TextEditAlertState(id: UUID(),
                                                       title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName,
                                                       text: "",
                                                       shouldReturn: false,
                                                       isPresenting: false)
        let tagEditAlertState = TextEditAlertState(id: UUID(),
                                                   title: L10n.tagListViewAlertForUpdateTitle,
                                                   message: L10n.tagListViewAlertForUpdateMessage,
                                                   placeholder: L10n.placeholderTagName,
                                                   text: "",
                                                   shouldReturn: false,
                                                   isPresenting: false)

        let viewController = NewTagCollectionViewController(state: state,
                                                            tagAdditionAlertState: tagAdditionAlertState,
                                                            tagEditAlertState: tagEditAlertState,
                                                            dependency: self,
                                                            menuBuilder: TagCollectionMenuBuilder(storage: userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagSelectionViewController(selectedTags: [Domain.Tag.Identity],
                                        context: Any?,
                                        delegate: TagSelectionDelegate) -> UIViewController?
    {
        let query: TagListQuery
        switch self._clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = TagSelectionViewModel(query: query,
                                              selectedTags: Set(selectedTags),
                                              context: context,
                                              clipCommandService: self._clipCommandService,
                                              settingStorage: self._userSettingStorage,
                                              logger: self.logger)
        viewModel.delegate = delegate
        let viewController = TagSelectionViewController(factory: self, viewModel: viewModel)
        return UINavigationController(rootViewController: viewController)
    }

    func makeMergeViewController(clipIds: [Clip.Identity], delegate: ClipMergeViewControllerDelegate) -> UIViewController? {
        let clips: [Clip]
        let tags: [Tag]
        switch self._clipQueryService.readClipAndTags(for: clipIds) {
        case let .success((fetchedClips, fetchedTags)):
            clips = fetchedClips
            tags = fetchedTags

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipMergeView. (\(error.rawValue))
            """))
            return nil
        }

        let viewModel = ClipMergeViewModel(clips: clips,
                                           tags: tags,
                                           commandService: self._clipCommandService,
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

        let presenter = SettingsPresenter(storage: self._userSettingStorage,
                                          availabilityStore: self.cloudAvailabilityObserver)
        viewController.factory = self
        viewController.presenter = presenter

        return UINavigationController(rootViewController: viewController)
    }

    func makeNewClipCollectionViewController() -> UIViewController? {
        let state = ClipCollectionState(selections: .init(),
                                        isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                        operation: .none,
                                        isEmptyMessageViewDisplaying: false,
                                        isCollectionViewDisplaying: false,
                                        alert: nil,
                                        source: .all,
                                        isDismissed: false,
                                        _clips: [:],
                                        _filteredClipIds: .init(),
                                        _previewingClipId: nil)
        let navigationBarState = ClipCollectionNavigationBarState(context: .init(albumId: nil),
                                                                  rightItems: [],
                                                                  leftItems: [],
                                                                  clipCount: 0,
                                                                  selectionCount: 0,
                                                                  operation: .none)
        let toolBarState = ClipCollectionToolBarState(context: .init(albumId: nil),
                                                      items: [],
                                                      isHidden: true,
                                                      _targetCount: 0,
                                                      _operation: .none,
                                                      alert: nil)

        let viewController = ClipCollectionViewController(state: state,
                                                          navigationBarState: navigationBarState,
                                                          toolBarState: toolBarState,
                                                          dependency: self,
                                                          thumbnailLoader: clipThumbnailLoader,
                                                          menuBuilder: ClipCollectionMenuBuilder(storage: userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeNewAlbumListViewController() -> UIViewController? {
        let state = AlbumListViewState(searchQuery: "",
                                       isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                       isEditing: false,
                                       isEmptyMessageViewDisplaying: false,
                                       isCollectionViewDisplaying: false,
                                       isSearchBarEnabled: false,
                                       isAddButtonEnabled: false,
                                       isDragInteractionEnabled: false,
                                       alert: nil,
                                       _albums: [:],
                                       _filteredAlbumIds: .init(),
                                       _searchStorage: .init())
        let addAlbumAlertState = TextEditAlertState(id: UUID(),
                                                    title: L10n.albumListViewAlertForAddTitle,
                                                    message: L10n.albumListViewAlertForAddMessage,
                                                    placeholder: L10n.placeholderAlbumName,
                                                    text: "",
                                                    shouldReturn: false,
                                                    isPresenting: false)
        let editAlbumAlertState = TextEditAlertState(id: UUID(),
                                                     title: L10n.albumListViewAlertForEditTitle,
                                                     message: L10n.albumListViewAlertForEditMessage,
                                                     placeholder: L10n.placeholderAlbumName,
                                                     text: "",
                                                     shouldReturn: false,
                                                     isPresenting: false)

        let viewController = NewAlbumListViewController(state: state,
                                                        albumAdditionAlertState: addAlbumAlertState,
                                                        albumEditAlertState: editAlbumAlertState,
                                                        dependency: self,
                                                        thumbnailLoader: albumThumbnailLoader,
                                                        menuBuilder: AlbumListMenuBuilder.self)

        return UINavigationController(rootViewController: viewController)
    }
}
