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

    private func isPresentingModal(having id: UUID) -> Bool {
        guard let detailViewController = rootViewController?.currentViewController else { return false }

        let isModal = { (id: UUID, viewController: UIViewController) -> Bool in
            if let viewController = viewController as? ModalController {
                return viewController.id == id
            }

            if let viewController = (viewController as? UINavigationController)?.topViewController as? ModalController {
                return viewController.id == id
            }

            return false
        }

        var topViewController = detailViewController
        while let presentedViewController = topViewController.presentedViewController {
            if isModal(id, presentedViewController) { return true }
            topViewController = presentedViewController
        }

        return isModal(id, topViewController)
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
        let viewController = makeClipCollectionViewController(from: .uncategorized)
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for query: ClipSearchQuery) -> Bool {
        let viewController = makeClipCollectionViewController(from: .search(query))
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for tag: Tag) -> Bool {
        let viewController = makeClipCollectionViewController(from: .tag(tag))
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for albumId: Album.Identity) -> Bool {
        let viewController = makeClipCollectionViewController(from: .album(albumId))
        guard let detailViewController = rootViewController?.currentViewController as? UINavigationController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipPreviewView(for clipId: Clip.Identity) -> Bool {
        let viewController = makeClipPreviewPageViewController(for: clipId)
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.present(viewController, animated: true, completion: nil)
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

    func showTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = TagSelectionModalState(id: id,
                                           selections: selections,
                                           isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let tagAdditionAlertState = TextEditAlertState(title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName)
        let viewController = TagSelectionModalController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         dependency: self)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showAlbumSelectionModal(id: UUID) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = AlbumSelectionModalState(id: id, isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let albumAdditionAlertState = TextEditAlertState(title: L10n.albumListViewAlertForAddTitle,
                                                         message: L10n.albumListViewAlertForAddMessage,
                                                         placeholder: L10n.placeholderAlbumName)
        let viewController = AlbumSelectionModalController(state: state,
                                                           albumAdditionAlertState: albumAdditionAlertState,
                                                           dependency: self,
                                                           thumbnailLoader: container.temporaryThumbnailLoader)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showClipMergeModal(id: UUID, clips: [Clip]) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = ClipMergeViewState(id: id, clips: clips)
        let viewController = ClipMergeViewController(state: state,
                                                     dependency: self,
                                                     thumbnailLoader: container.temporaryThumbnailLoader)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showClipEditModal(id: UUID, clipId: Clip.Identity) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = ClipEditViewState(id: id,
                                      clipId: clipId,
                                      isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let siteUrlEditAlertState = TextEditAlertState(title: L10n.clipPreviewViewAlertForEditSiteUrlTitle,
                                                       message: L10n.clipPreviewViewAlertForEditSiteUrlMessage,
                                                       placeholder: L10n.placeholderUrl)
        let viewController = ClipEditViewController(state: state,
                                                    siteUrlEditAlertState: siteUrlEditAlertState,
                                                    dependency: self,
                                                    thumbnailLoader: container.temporaryThumbnailLoader)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}
