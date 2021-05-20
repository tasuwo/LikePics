//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

extension SceneDependencyContainer {
    private var rootViewController: SceneRootViewController? {
        guard let windowScene = sceneResolver.resolveScene(),
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let rootViewController = sceneDelegate.window?.rootViewController as? SceneRootViewController
        else {
            return nil
        }
        return rootViewController
    }

    private var topViewController: UIViewController? {
        guard let detailViewController = rootViewController?.currentViewController else { return nil }
        var topViewController = detailViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }

    private func makeClipCollectionView(from source: ClipCollection.Source) -> UIViewController {
        let state = ClipCollectionViewRootState(source: source,
                                                isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        return ClipCollectionViewController(state: state,
                                            dependency: self,
                                            thumbnailLoader: container.clipThumbnailLoader,
                                            menuBuilder: ClipCollectionMenuBuilder(storage: container._userSettingStorage))
    }
}

extension SceneDependencyContainer: Router {
    // MARK: - Router

    func open(_ url: URL) -> Bool {
        guard UIApplication.shared.canOpenURL(url) else { return false }
        sceneResolver.resolveScene()?.open(url, options: nil, completionHandler: nil)
        return true
    }

    func showUncategorizedClipCollectionView() -> Bool {
        let viewController = makeClipCollectionView(from: .uncategorized)
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for query: ClipSearchQuery) -> Bool {
        let viewController = makeClipCollectionView(from: .search(query))
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for tag: Tag) -> Bool {
        let viewController = makeClipCollectionView(from: .tag(tag))
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for albumId: Album.Identity) -> Bool {
        let viewController = makeClipCollectionView(from: .album(albumId))
        guard let detailViewController = rootViewController?.currentViewController as? UINavigationController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipPreviewView(for clipId: Clip.Identity) -> Bool {
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

        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.present(navigationController, animated: true, completion: nil)

        return true
    }

    func showClipInformationView(clipId: Clip.Identity,
                                 itemId: ClipItem.Identity,
                                 clipInformationViewCache: ClipInformationViewCaching,
                                 transitioningController: ClipInformationTransitioningControllerProtocol) -> Bool
    {
        let state = ClipInformationViewState(clipId: clipId,
                                             itemId: itemId,
                                             isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let siteUrlEditAlertState = TextEditAlertState(title: L10n.clipPreviewViewAlertForEditSiteUrlTitle,
                                                       message: L10n.clipPreviewViewAlertForEditSiteUrlMessage,
                                                       placeholder: L10n.placeholderUrl)
        let viewController = ClipInformationViewController(state: state,
                                                           siteUrlEditAlertState: siteUrlEditAlertState,
                                                           dependency: self,
                                                           clipInformationViewCache: clipInformationViewCache,
                                                           transitioningController: transitioningController)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen

        guard let topViewController = topViewController else { return false }
        topViewController.present(viewController, animated: true, completion: nil)

        return false
    }

    func showTagSelectionModal(selections: Set<Tag.Identity>, completion: @escaping (Set<Tag>?) -> Void) -> Bool {
        struct Dependency: TagSelectionModalDependency {
            let userSettingStorage: UserSettingsStorageProtocol
            let clipCommandService: ClipCommandServiceProtocol
            let clipQueryService: ClipQueryServiceProtocol
            let tagSelectionCompleted: (Set<Tag>?) -> Void
        }
        let dependency = Dependency(userSettingStorage: container._userSettingStorage,
                                    clipCommandService: container._clipCommandService,
                                    clipQueryService: container._clipQueryService,
                                    tagSelectionCompleted: completion)

        let state = TagSelectionModalState(selections: selections,
                                           isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let tagAdditionAlertState = TextEditAlertState(title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName)
        let viewController = TagSelectionModalController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         dependency: dependency)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showAlbumSelectionModal(id: UUID) -> Bool {
        let state = AlbumSelectionModalState(id: id, isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let albumAdditionAlertState = TextEditAlertState(title: L10n.albumListViewAlertForAddTitle,
                                                         message: L10n.albumListViewAlertForAddMessage,
                                                         placeholder: L10n.placeholderAlbumName)
        let viewController = AlbumSelectionModalController(state: state,
                                                           albumAdditionAlertState: albumAdditionAlertState,
                                                           dependency: self,
                                                           thumbnailLoader: container.temporaryThumbnailLoader)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showClipMergeModal(id: UUID, clips: [Clip]) -> Bool {
        let state = ClipMergeViewState(id: id, clips: clips)
        let viewController = ClipMergeViewController(state: state,
                                                     dependency: self,
                                                     thumbnailLoader: container.temporaryThumbnailLoader)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showClipEditModal(for clipId: Clip.Identity, completion: ((Bool) -> Void)?) -> Bool {
        let state = ClipEditViewState(clipId: clipId,
                                      isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let siteUrlEditAlertState = TextEditAlertState(title: L10n.clipPreviewViewAlertForEditSiteUrlTitle,
                                                       message: L10n.clipPreviewViewAlertForEditSiteUrlMessage,
                                                       placeholder: L10n.placeholderUrl)
        let viewController = ClipEditViewController(state: state,
                                                    siteUrlEditAlertState: siteUrlEditAlertState,
                                                    dependency: self,
                                                    thumbnailLoader: container.temporaryThumbnailLoader)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}
