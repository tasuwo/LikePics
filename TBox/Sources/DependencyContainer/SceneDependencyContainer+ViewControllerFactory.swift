//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import ForestKit
import Smoothie
import TBoxCore
import TBoxUIKit
import UIKit

extension SceneDependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeClipCollectionViewController(from source: ClipCollection.Source) -> UIViewController & ViewLazyPresentable {
        let state = ClipCollectionViewRootState(source: source,
                                                isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        return ClipCollectionViewController(state: state,
                                            dependency: self,
                                            thumbnailLoader: container.clipThumbnailLoader,
                                            menuBuilder: ClipCollectionMenuBuilder(storage: container._userSettingStorage))
    }

    func makeClipCollectionViewController(_ state: ClipCollectionViewRootState) -> UIViewController & ViewLazyPresentable {
        return ClipCollectionViewController(state: state,
                                            dependency: self,
                                            thumbnailLoader: container.clipThumbnailLoader,
                                            menuBuilder: ClipCollectionMenuBuilder(storage: container._userSettingStorage))
    }

    func makeTagCollectionViewController(_ state: TagCollectionViewState?) -> UIViewController? {
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

    func makeAlbumListViewController(_ state: AlbumListViewState?) -> UIViewController? {
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
                                                     thumbnailLoader: container.albumThumbnailLoader,
                                                     menuBuilder: AlbumListMenuBuilder.self)

        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchViewController(_ state: SearchViewRootState?) -> UIViewController? {
        let state: SearchViewRootState = {
            if let state = state {
                return state
            } else {
                return .init(isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
            }
        }()
        let rootStore = Store(initialState: state, dependency: self as SearchViewRootDependency, reducer: searchViewRootReducer)

        let entryStore: SearchEntryViewController.Store = rootStore
            .proxy(SearchViewRootState.entryConverter, SearchViewRootAction.entryConverter)
            .eraseToAnyStoring()
        let resultStore: SearchResultViewController.Store = rootStore
            .proxy(SearchViewRootState.resultConverter, SearchViewRootAction.resultConverter)
            .eraseToAnyStoring()

        let resultsController = SearchResultViewController(store: resultStore,
                                                           thumbnailLoader: container.temporaryThumbnailLoader)
        let viewController = SearchEntryViewController(rootStore: rootStore,
                                                       store: entryStore,
                                                       searchResultViewController: resultsController)

        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController(_ state: SettingsViewState?) -> UIViewController {
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

    func makeClipPreviewPageViewController(for clipId: Clip.Identity) -> UIViewController {
        struct Dependency: ClipPreviewPageViewDependency & HasImageQueryService {
            let router: Router
            let clipCommandService: ClipCommandServiceProtocol
            let clipQueryService: ClipQueryServiceProtocol
            let clipInformationTransitioningController: ClipInformationTransitioningController?
            let imageQueryService: ImageQueryServiceProtocol
            let informationViewCache: ClipInformationViewCaching?
            let previewLoader: PreviewLoader
            let transitionLock: TransitionLock
        }

        let informationViewCacheState = ClipInformationViewCacheState(isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let informationViewCacheController = ClipInformationViewCacheController(state: informationViewCacheState,
                                                                                dependency: self)

        let previewTransitioningController = ClipPreviewTransitioningController(lock: container.transitionLock, logger: container.logger)
        let informationTransitionController = ClipInformationTransitioningController(lock: container.transitionLock, logger: container.logger)
        let transitionController = ClipPreviewPageTransitionController(previewTransitioningController: previewTransitioningController,
                                                                       informationTransitionController: informationTransitionController)

        let dependency = Dependency(router: self,
                                    clipCommandService: container._clipCommandService,
                                    clipQueryService: container._clipQueryService,
                                    clipInformationTransitioningController: informationTransitionController,
                                    imageQueryService: container._imageQueryService,
                                    informationViewCache: informationViewCacheController,
                                    previewLoader: container._previewLoader,
                                    transitionLock: container.transitionLock)

        let state = ClipPreviewPageViewRootState(clipId: clipId)
        let viewController = ClipPreviewPageViewController(state: state,
                                                           cacheController: informationViewCacheController,
                                                           dependency: dependency,
                                                           factory: self,
                                                           transitionController: transitionController)

        transitionController.setup(baseViewController: viewController)

        let navigationController = ClipPreviewNavigationController(pageViewController: viewController)
        navigationController.transitioningDelegate = previewTransitioningController
        navigationController.modalPresentationStyle = .fullScreen

        return navigationController
    }

    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController? {
        let store = ClipPreviewViewState(item: item)
        let viewController = ClipPreviewViewController(state: store, dependency: self)
        return viewController
    }
}
