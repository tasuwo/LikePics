//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeature
import ClipPreviewPlayConfigurationModalFeature
import Combine
import Common
import CompositeKit
import Domain
import Environment
import LikePicsUIKit
import MobileTransition
import Smoothie
import UIKit

extension SceneDependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    public func makeClipCollectionViewController(from source: ClipCollection.Source) -> RestorableViewController & ViewLazyPresentable {
        let state = ClipCollectionViewRootState(
            source: source,
            isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems()
        )
        return ClipCollectionViewController(
            state: state,
            dependency: self,
            thumbnailProcessingQueue: container.clipThumbnailProcessingQueue,
            menuBuilder: ClipCollectionMenuBuilder(storage: container.userSettingStorage),
            modalRouter: self,
            appBundle: container.appBundle
        )
    }

    public func makeClipCollectionViewController(_ state: ClipCollectionViewRootState) -> RestorableViewController & ViewLazyPresentable {
        return ClipCollectionViewController(
            state: state,
            dependency: self,
            thumbnailProcessingQueue: container.clipThumbnailProcessingQueue,
            menuBuilder: ClipCollectionMenuBuilder(storage: container.userSettingStorage),
            modalRouter: self,
            appBundle: container.appBundle
        )
    }

    public func makeTagCollectionViewController(_ state: TagCollectionViewState?) -> RestorableViewController? {
        let state: TagCollectionViewState = {
            if let state = state {
                return state
            } else {
                return .init(isSomeItemsHidden: container.userSettingStorage.readShowHiddenItems())
            }
        }()
        let tagAdditionAlertState = TextEditAlertState(
            title: L10n.tagListViewAlertForAddTitle,
            message: L10n.tagListViewAlertForAddMessage,
            placeholder: L10n.placeholderTagName
        )
        let tagEditAlertState = TextEditAlertState(
            title: L10n.tagListViewAlertForUpdateTitle,
            message: L10n.tagListViewAlertForUpdateMessage,
            placeholder: L10n.placeholderTagName
        )

        let viewController = TagCollectionViewController(
            state: state,
            tagAdditionAlertState: tagAdditionAlertState,
            tagEditAlertState: tagEditAlertState,
            dependency: self,
            menuBuilder: TagCollectionMenuBuilder(storage: container.userSettingStorage),
            appBundle: container.appBundle
        )

        return UINavigationController(rootViewController: viewController)
    }

    public func makeAlbumListViewController(_ state: AlbumListViewState?) -> RestorableViewController? {
        let state: AlbumListViewState = {
            if let state = state {
                return state
            } else {
                return .init(isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems())
            }
        }()
        let addAlbumAlertState = TextEditAlertState(
            title: L10n.albumListViewAlertForAddTitle,
            message: L10n.albumListViewAlertForAddMessage,
            placeholder: L10n.placeholderAlbumName
        )
        let editAlbumAlertState = TextEditAlertState(
            title: L10n.albumListViewAlertForEditTitle,
            message: L10n.albumListViewAlertForEditMessage,
            placeholder: L10n.placeholderAlbumName
        )

        let viewController = AlbumListViewController(
            state: state,
            albumAdditionAlertState: addAlbumAlertState,
            albumEditAlertState: editAlbumAlertState,
            dependency: self,
            thumbnailProcessingQueue: container.albumThumbnailProcessingQueue,
            imageQueryService: container.imageQueryService,
            menuBuilder: AlbumListMenuBuilder.self,
            appBundle: container.appBundle
        )

        return UINavigationController(rootViewController: viewController)
    }

    public func makeSearchViewController(_ state: SearchViewRootState?) -> RestorableViewController? {
        let state: SearchViewRootState = {
            if let state = state {
                return state
            } else {
                return .init(isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems())
            }
        }()
        let viewController = SearchEntryViewController(
            state: state,
            dependency: self,
            thumbnailProcessingQueue: container.temporaryThumbnailProcessingQueue,
            imageQueryService: container.imageQueryService,
            appBundle: container.appBundle
        )

        return UINavigationController(rootViewController: viewController)
    }

    public func makeSettingsViewController(_ state: SettingsViewState?) -> RestorableViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.module)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let state: SettingsViewState = {
            if let state = state {
                return state
            } else {
                return SettingsViewState(
                    cloudAvailability: nil,
                    isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems(),
                    isICloudSyncEnabled: container.userSettingStorage.readEnabledICloudSync()
                )
            }
        }()
        let store = Store(initialState: state, dependency: self, reducer: SettingsViewReducer())
        viewController.store = store
        viewController.router = router
        viewController.userSettingsStorage = container.userSettingStorage
        viewController.appBundle = container.appBundle

        return UINavigationController(rootViewController: viewController)
    }

    public func makeClipPreviewPageViewController(
        clips: [Clip],
        query: ClipPreviewPageQuery,
        indexPath: ClipCollection.IndexPath
    ) -> UIViewController {
        struct Dependency: ClipPreviewPageViewDependency, HasImageQueryService {
            let router: Router
            let clipCommandService: ClipCommandServiceProtocol
            let clipQueryService: ClipQueryServiceProtocol
            let clipItemInformationTransitioningController: ClipItemInformationTransitioningController?
            let imageQueryService: ImageQueryServiceProtocol
            let transitionLock: TransitionLock
            let userSettingStorage: UserSettingsStorageProtocol
            let clipPreviewPlayConfigurationStorage: ClipPreviewPlayConfigurationStorageProtocol
            let previewPrefetcher: PreviewPrefetchable
        }

        let previewTransitioningController = ClipPreviewTransitioningController(lock: container.transitionLock)
        let informationTransitionController = ClipItemInformationTransitioningController(lock: container.transitionLock)
        let itemListTransitionController = ClipItemListTransitioningController(lock: container.transitionLock)
        let transitionDispatcher = ClipPreviewPageTransitionController(
            previewTransitioningController: previewTransitioningController,
            informationTransitionController: informationTransitionController
        )

        let dependency = Dependency(
            router: self,
            clipCommandService: container.clipCommandService,
            clipQueryService: container.clipQueryService,
            clipItemInformationTransitioningController: informationTransitionController,
            imageQueryService: container.imageQueryService,
            transitionLock: container.transitionLock,
            userSettingStorage: container.userSettingStorage,
            clipPreviewPlayConfigurationStorage: container.clipPreviewPlayConfigurationStorage,
            previewPrefetcher: container.previewPrefetcher
        )

        let state = ClipPreviewPageViewRootState(
            clips: clips,
            playConfiguration: container.clipPreviewPlayConfigurationStorage.fetchClipPreviewPlayConfiguration(),
            query: query,
            isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems(),
            indexPath: indexPath
        )
        let viewController = ClipPreviewPageViewController(
            state: state,
            dependency: dependency,
            factory: self,
            previewPrefetcher: container.previewPrefetcher,
            transitionDispatcher: transitionDispatcher,
            itemListTransitionController: itemListTransitionController,
            modalRouter: self,
            appBundle: container.appBundle
        )

        transitionDispatcher.setup(baseViewController: viewController)

        let navigationController = ClipPreviewNavigationController(pageViewController: viewController)
        navigationController.transitioningDelegate = previewTransitioningController
        navigationController.modalPresentationStyle = .fullScreen

        return navigationController
    }

    public func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController? {
        let viewController = ClipPreviewViewController(
            state: .init(item: item),
            imageQueryService: container.imageQueryService,
            thumbnailMemoryCache: container.clipThumbnailProcessingQueue.config.memoryCache,
            thumbnailDiskCache: container.clipDiskCache,
            processingQueue: container.previewProcessingQueue
        )
        return viewController
    }
}
