//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CompositeKit
import Domain
import LikePicsCore
import LikePicsUIKit
import Smoothie
import UIKit

extension SceneDependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeClipCollectionViewController(from source: ClipCollection.Source) -> RestorableViewController & ViewLazyPresentable {
        let state = ClipCollectionViewRootState(source: source,
                                                isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        return ClipCollectionViewController(state: state,
                                            dependency: self,
                                            thumbnailPipeline: container.clipThumbnailPipeline,
                                            menuBuilder: ClipCollectionMenuBuilder(storage: container._userSettingStorage))
    }

    func makeClipCollectionViewController(_ state: ClipCollectionViewRootState) -> RestorableViewController & ViewLazyPresentable {
        return ClipCollectionViewController(state: state,
                                            dependency: self,
                                            thumbnailPipeline: container.clipThumbnailPipeline,
                                            menuBuilder: ClipCollectionMenuBuilder(storage: container._userSettingStorage))
    }

    func makeTagCollectionViewController(_ state: TagCollectionViewState?) -> RestorableViewController? {
        let state: TagCollectionViewState = {
            if let state = state {
                return state
            } else {
                return .init(isSomeItemsHidden: container._userSettingStorage.readShowHiddenItems())
            }
        }()
        let tagAdditionAlertState = TextEditAlertState(title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName)
        let tagEditAlertState = TextEditAlertState(title: L10n.tagListViewAlertForUpdateTitle,
                                                   message: L10n.tagListViewAlertForUpdateMessage,
                                                   placeholder: L10n.placeholderTagName)

        let viewController = TagCollectionViewController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         tagEditAlertState: tagEditAlertState,
                                                         dependency: self,
                                                         menuBuilder: TagCollectionMenuBuilder(storage: container._userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumListViewController(_ state: AlbumListViewState?) -> RestorableViewController? {
        let state: AlbumListViewState = {
            if let state = state {
                return state
            } else {
                return .init(isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
            }
        }()
        let addAlbumAlertState = TextEditAlertState(title: L10n.albumListViewAlertForAddTitle,
                                                    message: L10n.albumListViewAlertForAddMessage,
                                                    placeholder: L10n.placeholderAlbumName)
        let editAlbumAlertState = TextEditAlertState(title: L10n.albumListViewAlertForEditTitle,
                                                     message: L10n.albumListViewAlertForEditMessage,
                                                     placeholder: L10n.placeholderAlbumName)

        let viewController = AlbumListViewController(state: state,
                                                     albumAdditionAlertState: addAlbumAlertState,
                                                     albumEditAlertState: editAlbumAlertState,
                                                     dependency: self,
                                                     thumbnailPipeline: container.albumThumbnailPipeline,
                                                     imageQueryService: container._imageQueryService,
                                                     menuBuilder: AlbumListMenuBuilder.self)

        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchViewController(_ state: SearchViewRootState?) -> RestorableViewController? {
        let state: SearchViewRootState = {
            if let state = state {
                return state
            } else {
                return .init(isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
            }
        }()
        let viewController = SearchEntryViewController(state: state,
                                                       dependency: self,
                                                       thumbnailPipeline: container.temporaryThumbnailPipeline,
                                                       imageQueryService: container._imageQueryService)

        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController(_ state: SettingsViewState?) -> RestorableViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let state: SettingsViewState = {
            if let state = state {
                return state
            } else {
                return SettingsViewState(cloudAvailability: nil,
                                         isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems(),
                                         isICloudSyncEnabled: container._userSettingStorage.readEnabledICloudSync())
            }
        }()
        let store = Store(initialState: state, dependency: self, reducer: SettingsViewReducer())
        viewController.store = store

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewPageViewController(filteredClipIds: Set<Clip.Identity>,
                                           clips: [Clip],
                                           query: ClipPreviewPageViewState.Query,
                                           indexPath: ClipCollection.IndexPath) -> UIViewController
    {
        struct Dependency: ClipPreviewPageViewDependency & HasImageQueryService {
            let router: Router
            let clipCommandService: ClipCommandServiceProtocol
            let clipQueryService: ClipQueryServiceProtocol
            let clipItemInformationTransitioningController: ClipItemInformationTransitioningController?
            let imageQueryService: ImageQueryServiceProtocol
            let transitionLock: TransitionLock
            let userSettingStorage: UserSettingsStorageProtocol
        }

        let previewTransitioningController = ClipPreviewTransitioningController(lock: container.transitionLock, logger: container.logger)
        let informationTransitionController = ClipItemInformationTransitioningController(lock: container.transitionLock, logger: container.logger)
        let itemListTransitionController = ClipItemListTransitioningController(lock: container.transitionLock, logger: container.logger)
        let transitionDispatcher = ClipPreviewPageTransitionController(previewTransitioningController: previewTransitioningController,
                                                                       informationTransitionController: informationTransitionController)

        let dependency = Dependency(router: self,
                                    clipCommandService: container._clipCommandService,
                                    clipQueryService: container._clipQueryService,
                                    clipItemInformationTransitioningController: informationTransitionController,
                                    imageQueryService: container._imageQueryService,
                                    transitionLock: container.transitionLock,
                                    userSettingStorage: container._userSettingStorage)

        let state = ClipPreviewPageViewRootState(filteredClipIds: filteredClipIds,
                                                 clips: clips,
                                                 query: query,
                                                 isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems(),
                                                 indexPath: indexPath)
        let viewController = ClipPreviewPageViewController(state: state,
                                                           dependency: dependency,
                                                           factory: self,
                                                           transitionDispatcher: transitionDispatcher,
                                                           itemListTransitionController: itemListTransitionController,
                                                           previewPrefetcher: container.previewPrefetcher)

        transitionDispatcher.setup(baseViewController: viewController)

        let navigationController = ClipPreviewNavigationController(pageViewController: viewController)
        navigationController.transitioningDelegate = previewTransitioningController
        navigationController.modalPresentationStyle = .fullScreen

        return navigationController
    }

    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController? {
        let viewController = ClipPreviewViewController(state: .init(item: item),
                                                       imageQueryService: container._imageQueryService,
                                                       thumbnailMemoryCache: container.clipThumbnailPipeline.config.memoryCache,
                                                       thumbnailDiskCache: container.clipDiskCache,
                                                       pipeline: container.previewPipeline)
        return viewController
    }
}
