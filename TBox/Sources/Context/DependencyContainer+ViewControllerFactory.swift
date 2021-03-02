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
        let state = ClipCollectionState(source: .all,
                                        title: nil,
                                        operation: .none,
                                        clips: .init(_values: [:],
                                                     _selectedIds: .init(),
                                                     _displayableIds: .init()),
                                        previewingClipId: nil,
                                        isEmptyMessageViewDisplaying: false,
                                        isCollectionViewDisplaying: false,
                                        alert: nil,
                                        isDismissed: false,
                                        isSomeItemsHidden: !userSettingStorage.readShowHiddenItems())
        let navigationBarState = ClipCollectionNavigationBarState(source: .all,
                                                                  operation: .none,
                                                                  rightItems: [],
                                                                  leftItems: [],
                                                                  clipCount: 0,
                                                                  selectionCount: 0)
        let toolBarState = ClipCollectionToolBarState(source: .all,
                                                      operation: .none,
                                                      items: [],
                                                      isHidden: true,
                                                      _targetCount: 0,
                                                      alert: nil)

        let viewController = ClipCollectionViewController(state: state,
                                                          navigationBarState: navigationBarState,
                                                          toolBarState: toolBarState,
                                                          dependency: self,
                                                          thumbnailLoader: clipThumbnailLoader,
                                                          menuBuilder: ClipCollectionMenuBuilder(storage: userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagCollectionViewController() -> UIViewController? {
        let state = TagCollectionViewState(tags: .init(_values: [:],
                                                       _selectedIds: .init(),
                                                       _displayableIds: .init()),
                                           searchQuery: "",
                                           isCollectionViewDisplaying: false,
                                           isEmptyMessageViewDisplaying: false,
                                           isSearchBarEnabled: false,
                                           alert: nil,
                                           _isSomeItemsHidden: _userSettingStorage.readShowHiddenItems(),
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

        let viewController = TagCollectionViewController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         tagEditAlertState: tagEditAlertState,
                                                         dependency: self,
                                                         menuBuilder: TagCollectionMenuBuilder(storage: userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumListViewController() -> UIViewController? {
        let state = AlbumListViewState(searchQuery: "",
                                       albums: .init(_values: [:],
                                                     _selectedIds: .init(),
                                                     _displayableIds: .init()),
                                       isEditing: false,
                                       isEmptyMessageViewDisplaying: false,
                                       isCollectionViewDisplaying: false,
                                       isSearchBarEnabled: false,
                                       isAddButtonEnabled: true,
                                       isDragInteractionEnabled: false,
                                       alert: nil,
                                       _isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
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

        let viewController = AlbumListViewController(state: state,
                                                     albumAdditionAlertState: addAlbumAlertState,
                                                     albumEditAlertState: editAlbumAlertState,
                                                     dependency: self,
                                                     thumbnailLoader: albumThumbnailLoader,
                                                     menuBuilder: AlbumListMenuBuilder.self)

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
}
