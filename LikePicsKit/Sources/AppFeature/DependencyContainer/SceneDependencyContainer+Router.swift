//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import AlbumMultiSelectionModalFeature
import AlbumSelectionModalFeature
import ClipCreationFeature
import ClipCreationFeatureCore
import ClipPreviewPlayConfigurationModalFeature
import Common
import Domain
import Environment
import Foundation
import LikePicsUIKit
import MobileTransition
import TagSelectionModalFeature
import UIKit
import WebKit

extension SceneDependencyContainer {
    private var rootViewController: SceneRootViewController? {
        guard let windowScene = sceneResolver.resolveScene(),
              let sceneDelegate = windowScene.delegate as? UIWindowSceneDelegate,
              let rootViewController = sceneDelegate.window??.rootViewController as? SceneRootViewController
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

    private func dismissAllModals(_ completion: @escaping (Bool) -> Void) {
        guard let detailViewController = rootViewController?.currentViewController else {
            completion(false)
            return
        }

        var topViewController = detailViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        if topViewController == detailViewController {
            completion(true)
            return
        }

        dismiss(topViewController, until: detailViewController) {
            completion(true)
        }
    }

    private func dismiss(_ viewController: UIViewController?,
                         until rootViewController: UIViewController,
                         completion: @escaping () -> Void)
    {
        let presentingViewController = viewController?.presentingViewController
        viewController?.dismiss(animated: true, completion: {
            if viewController === rootViewController {
                completion()
                return
            }

            guard let viewController = presentingViewController else {
                completion()
                return
            }

            self.dismiss(viewController, until: rootViewController, completion: completion)
        })
    }
}

extension SceneDependencyContainer: Router {
    // MARK: - Router

    public func open(_ url: URL) -> Bool {
        guard UIApplication.shared.canOpenURL(url) else { return false }
        sceneResolver.resolveScene()?.open(url, options: nil, completionHandler: nil)
        return true
    }

    public func showUncategorizedClipCollectionView() -> Bool {
        let viewController = makeClipCollectionViewController(from: .uncategorized)
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    public func showClipCollectionView(for query: ClipSearchQuery) -> Bool {
        let viewController = makeClipCollectionViewController(from: .search(query))
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    public func showClipCollectionView(for tag: Tag) -> Bool {
        let viewController = makeClipCollectionViewController(from: .tag(tag))
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    public func showClipCollectionView(for albumId: Album.Identity) -> Bool {
        let viewController = makeClipCollectionViewController(from: .album(albumId))
        guard let detailViewController = rootViewController?.currentViewController as? UINavigationController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    public func showClipPreviewView(clips: [Clip],
                                    query: ClipPreviewPageQuery,
                                    indexPath: ClipCollection.IndexPath) -> Bool
    {
        let viewController = makeClipPreviewPageViewController(clips: clips,
                                                               query: query,
                                                               indexPath: indexPath)
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.present(viewController, animated: true, completion: nil)
        return true
    }

    public func showClipInformationView(clipId: Clip.Identity,
                                        itemId: ClipItem.Identity,
                                        transitioningController: ClipItemInformationTransitioningControllable) -> Bool
    {
        let state = ClipItemInformationViewState(clipId: clipId,
                                                 itemId: itemId,
                                                 isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems())
        let siteUrlEditAlertState = TextEditAlertState(title: L10n.alertForEditSiteUrlTitle,
                                                       message: L10n.alertForEditSiteUrlMessage,
                                                       placeholder: L10n.placeholderUrl)
        let viewController = ClipItemInformationViewController(state: state,
                                                               siteUrlEditAlertState: siteUrlEditAlertState,
                                                               dependency: self,
                                                               transitioningController: transitioningController,
                                                               modalRouter: self)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen

        guard let topViewController = topViewController else { return false }
        topViewController.present(viewController, animated: true, completion: nil)

        return true
    }

    public func showFindView() -> Bool {
        let state = FindViewState()
        let viewController = FindViewController(state: state, dependency: self, modalRouter: self)
        guard let detailViewController = rootViewController?.currentViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    public func routeToClipCollectionView(for tag: Tag) {
        guard let rootViewController = rootViewController else { return }
        dismissAllModals { isSucceeded in
            guard isSucceeded else { return }

            rootViewController.select(.tags)

            guard let rootViewController = self.topViewController else { return }
            (rootViewController as? UINavigationController)?.popToRootViewController(animated: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
                _ = self.showClipCollectionView(for: tag)
            })
        }
    }

    public func routeToClipCollectionView(forAlbumId albumId: Album.Identity) {
        guard let rootViewController = rootViewController else { return }
        dismissAllModals { isSucceeded in
            guard isSucceeded else { return }

            rootViewController.select(.albums)

            guard let rootViewController = self.topViewController else { return }
            (rootViewController as? UINavigationController)?.popToRootViewController(animated: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
                _ = self.showClipCollectionView(for: albumId)
            })
        }
    }
}

extension SceneDependencyContainer: AlbumMultiSelectionModalRouter {
    // MARK: - AlbumMultiSelectionModalRouter

    public func showAlbumMultiSelectionModal(id: UUID, selections: Set<Album.Identity>) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = AlbumMultiSelectionModalState(id: id,
                                                  selections: selections,
                                                  isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems())
        let albumAdditionAlertState = TextEditAlertState(title: L10n.albumListViewAlertForAddTitle,
                                                         message: L10n.albumListViewAlertForAddMessage,
                                                         placeholder: L10n.placeholderAlbumName)
        let viewController = AlbumMultiSelectionModalController(state: state,
                                                                albumAdditionAlertState: albumAdditionAlertState,
                                                                dependency: self)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}

extension SceneDependencyContainer: AlbumSelectionModalRouter {
    // MARK: - AlbumSelectionModalRouter

    public func showAlbumSelectionModal(id: UUID) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = AlbumSelectionModalState(id: id, isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems())
        let albumAdditionAlertState = TextEditAlertState(title: L10n.albumListViewAlertForAddTitle,
                                                         message: L10n.albumListViewAlertForAddMessage,
                                                         placeholder: L10n.placeholderAlbumName)
        let viewController = AlbumSelectionModalController(state: state,
                                                           albumAdditionAlertState: albumAdditionAlertState,
                                                           dependency: self,
                                                           thumbnailProcessingQueue: container.temporaryThumbnailProcessingQueue,
                                                           imageQueryService: container.imageQueryService)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}

extension SceneDependencyContainer: ClipCreationModalRouter {
    // MARK: - ClipCreationModalRouter

    public func showClipCreationModal(id: UUID, webView: WKWebView) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }
        guard let currentUrl = webView.url else { return false }

        struct Dependency: ClipCreationViewDependency {
            var clipRecipeFactory: ClipRecipeFactoryProtocol
            var clipStore: ClipStorable
            var imageLoader: ImageLoadable
            var imageSourceProvider: ImageLoadSourceResolver
            var userSettingsStorage: UserSettingsStorageProtocol
            var modalNotificationCenter: ModalNotificationCenter
        }
        let imageLoader = ImageLoader()
        let dependency = Dependency(clipRecipeFactory: ClipRecipeFactory(),
                                    clipStore: container.clipStore,
                                    imageLoader: imageLoader,
                                    imageSourceProvider: WebPageImageLoadSourceResolver(webView: webView),
                                    userSettingsStorage: container.userSettingStorage,
                                    modalNotificationCenter: .default)

        let viewController = ClipCreationViewController(state: .init(id: id,
                                                                     source: .webPageImage,
                                                                     url: currentUrl,
                                                                     isSomeItemsHidden: container.userSettingStorage.readShowHiddenItems()),
                                                        dependency: dependency,
                                                        thumbnailProcessingQueue: container.temporaryThumbnailProcessingQueue,
                                                        imageLoader: imageLoader,
                                                        modalRouter: self)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}

extension SceneDependencyContainer: ClipItemListModalRouter {
    // MARK: - ClipItemListModalRouter

    public func showClipItemListModal(id: UUID,
                                      clipId: Clip.Identity,
                                      clipItems: [ClipItem],
                                      transitioningController: ClipItemListTransitioningControllable) -> Bool
    {
        let state = ClipItemListState(id: id,
                                      clipId: clipId,
                                      clipItems: clipItems,
                                      isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems())
        let viewController = ClipItemListViewController(state: .init(listState: state,
                                                                     navigationBarState: .init(),
                                                                     toolBarState: .init()),
                                                        siteUrlEditAlertState: .init(title: L10n.alertForEditSiteUrlTitle,
                                                                                     message: L10n.alertForEditClipItemsSiteUrlMessage,
                                                                                     placeholder: L10n.placeholderUrl),
                                                        dependency: self,
                                                        thumbnailProcessingQueue: container.clipItemThumbnailProcessingQueue)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen

        guard let topViewController = topViewController else { return false }
        topViewController.present(viewController, animated: true, completion: nil)

        return true
    }
}

extension SceneDependencyContainer: ClipMergeModalRouter {
    // MARK: - ClipMergeModalRouter

    public func showClipMergeModal(id: UUID, clips: [Clip]) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = ClipMergeViewState(id: id, clips: clips)
        let viewController = ClipMergeViewController(state: state,
                                                     dependency: self,
                                                     thumbnailProcessingQueue: container.temporaryThumbnailProcessingQueue,
                                                     imageQueryService: container.imageQueryService,
                                                     modalRouter: self)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}

extension SceneDependencyContainer: TagSelectionModalRouter {
    // MARK: - TagSelectionModalRouter

    public func showTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let state = TagSelectionModalState(id: id,
                                           selections: selections,
                                           isSomeItemsHidden: !container.userSettingStorage.readShowHiddenItems())
        let tagAdditionAlertState = TextEditAlertState(title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName)
        let viewController = TagSelectionModalController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         dependency: self)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}

extension SceneDependencyContainer: ClipPreviewPlayConfigurationModalRouter {
    // MARK: - ClipPreviewPlayConfigurationModalRouter

    public func showClipPreviewPlayConfigurationModal(id: UUID) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        let viewController = ClipPreviewPlayConfigurationModalController(id: id,
                                                                         modalNotificationCenter: container.modalNotificationCenter,
                                                                         storage: container.clipPreviewPlayConfigurationStorage)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}
