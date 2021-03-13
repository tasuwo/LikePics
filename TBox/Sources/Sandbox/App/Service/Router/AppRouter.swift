//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

extension DependencyContainer {
    private var rootViewController: AppRootSplitViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let rootViewController = sceneDelegate.window?.rootViewController as? AppRootSplitViewController
        else {
            return nil
        }
        return rootViewController
    }

    private var topViewController: UIViewController? {
        guard let detailViewController = rootViewController?.currentDetailViewController else { return nil }
        var topViewController = detailViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }

    private func makeClipCollectionView(from source: ClipCollection.Source) -> UIViewController {
        let state = ClipCollectionState(source: source,
                                        title: nil,
                                        operation: .none,
                                        clips: .init(_values: [:],
                                                     _selectedIds: .init(),
                                                     _displayableIds: .init()),
                                        previewingClipId: nil,
                                        isEmptyMessageViewDisplaying: false,
                                        isCollectionViewDisplaying: false,
                                        isDragInteractionEnabled: false,
                                        alert: nil,
                                        isDismissed: false,
                                        isSomeItemsHidden: !userSettingStorage.readShowHiddenItems())
        let navigationBarState = ClipCollectionNavigationBarState(source: source,
                                                                  operation: .none,
                                                                  rightItems: [],
                                                                  leftItems: [],
                                                                  clipCount: 0,
                                                                  selectionCount: 0)
        let toolBarState = ClipCollectionToolBarState(source: source,
                                                      operation: .none,
                                                      items: [],
                                                      isHidden: true,
                                                      _selections: .init(),
                                                      alert: nil)

        return ClipCollectionViewController(state: state,
                                            navigationBarState: navigationBarState,
                                            toolBarState: toolBarState,
                                            dependency: self,
                                            thumbnailLoader: clipThumbnailLoader,
                                            menuBuilder: ClipCollectionMenuBuilder(storage: userSettingStorage))
    }
}

extension DependencyContainer: Router {
    // MARK: - Router

    func open(_ url: URL) -> Bool {
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }

    func showUncategorizedClipCollectionView() -> Bool {
        let viewController = makeClipCollectionView(from: .search(.tag(nil)))
        guard let detailViewController = rootViewController?.currentDetailViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for tag: Tag) -> Bool {
        let viewController = makeClipCollectionView(from: .search(.tag(tag)))
        guard let detailViewController = rootViewController?.currentDetailViewController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipCollectionView(for albumId: Album.Identity) -> Bool {
        let viewController = makeClipCollectionView(from: .album(albumId))
        guard let detailViewController = rootViewController?.currentDetailViewController as? UINavigationController else { return false }
        detailViewController.show(viewController, sender: nil)
        return true
    }

    func showClipPreviewView(for clipId: Clip.Identity) -> Bool {
        class Dependency: ClipPreviewPageViewDependency & HasImageQueryService {
            let router: Router
            let clipCommandService: ClipCommandServiceProtocol
            let clipQueryService: ClipQueryServiceProtocol
            weak var clipInformationTransitioningController: ClipInformationTransitioningController?
            let imageQueryService: ImageQueryServiceProtocol
            weak var clipInformationViewDataSource: ClipInformationViewDataSource?

            init(router: Router,
                 clipCommandService: ClipCommandServiceProtocol,
                 clipQueryService: ClipQueryServiceProtocol,
                 clipInformationTransitioningController: ClipInformationTransitioningController?,
                 imageQueryService: ImageQueryServiceProtocol)
            {
                self.router = router
                self.clipCommandService = clipCommandService
                self.clipQueryService = clipQueryService
                self.clipInformationTransitioningController = clipInformationTransitioningController
                self.imageQueryService = imageQueryService
            }
        }

        let previewTransitioningController = ClipPreviewTransitioningController(logger: logger)
        let informationTransitionController = ClipInformationTransitioningController(logger: logger)
        let transitionController = ClipPreviewPageTransitionController(previewTransitioningController: previewTransitioningController,
                                                                       informationTransitionController: informationTransitionController)

        let dependency = Dependency(router: self,
                                    clipCommandService: clipCommandService,
                                    clipQueryService: clipQueryService,
                                    clipInformationTransitioningController: informationTransitionController,
                                    imageQueryService: imageQueryService)

        let state = ClipPreviewPageViewState(clipId: clipId,
                                             interPageSpacing: 40,
                                             isFullscreen: false,
                                             currentIndex: nil,
                                             items: [],
                                             alert: nil,
                                             isDismissed: false)
        let barState = ClipPreviewPageBarState(parentState: state,
                                               verticalSizeClass: .unspecified,
                                               leftBarButtonItems: [],
                                               rightBarButtonItems: [],
                                               toolBarItems: [],
                                               isToolBarHidden: false,
                                               alert: nil)
        let viewController = ClipPreviewPageViewController(state: state,
                                                           barState: barState,
                                                           dependency: dependency,
                                                           factory: self,
                                                           transitionController: transitionController)

        dependency.clipInformationViewDataSource = viewController
        transitionController.setup(factory: viewController, baseViewController: viewController)

        let navigationController = ClipPreviewNavigationController(pageViewController: viewController)
        navigationController.transitioningDelegate = previewTransitioningController
        navigationController.modalPresentationStyle = .fullScreen

        guard let detailViewController = rootViewController?.currentDetailViewController else { return false }
        detailViewController.present(navigationController, animated: true, completion: nil)

        return true
    }

    func showClipInformationView(clipId: Clip.Identity,
                                 itemId: ClipItem.Identity,
                                 informationViewDataSource: ClipInformationViewDataSource,
                                 transitioningController: ClipInformationTransitioningControllerProtocol) -> Bool
    {
        let state = ClipInformationViewState(clipId: clipId,
                                             itemId: itemId,
                                             clip: nil,
                                             tags: .init(_values: [:], _selectedIds: .init(), _displayableIds: .init()),
                                             item: nil,
                                             isSomeItemsHidden: userSettingStorage.readShowHiddenItems(),
                                             isHiddenStatusBar: false,
                                             alert: nil,
                                             isDismissed: false)
        let siteUrlEditAlertState = TextEditAlertState(id: UUID(),
                                                       title: L10n.clipPreviewViewAlertForEditSiteUrlTitle,
                                                       message: L10n.clipPreviewViewAlertForEditSiteUrlMessage,
                                                       placeholder: L10n.placeholderUrl,
                                                       text: "",
                                                       shouldReturn: false,
                                                       isPresenting: false)
        let viewController = ClipInformationViewController(state: state,
                                                           siteUrlEditAlertState: siteUrlEditAlertState,
                                                           dependency: self,
                                                           informationViewDataSource: informationViewDataSource,
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
        let dependency = Dependency(userSettingStorage: userSettingStorage,
                                    clipCommandService: clipCommandService,
                                    clipQueryService: clipQueryService,
                                    tagSelectionCompleted: completion)

        let state = TagSelectionModalState(searchQuery: "",
                                           tags: .init(_values: [:],
                                                       _selectedIds: selections,
                                                       _displayableIds: .init()),
                                           isCollectionViewDisplaying: false,
                                           isEmptyMessageViewDisplaying: false,
                                           isSearchBarEnabled: false,
                                           alert: nil,
                                           isDismissed: false,
                                           _isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                           _searchStorage: .init())
        let tagAdditionAlertState = TextEditAlertState(id: UUID(),
                                                       title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName,
                                                       text: "",
                                                       shouldReturn: false,
                                                       isPresenting: false)
        let viewController = TagSelectionModalController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         dependency: dependency)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showAlbumSelectionModal(completion: @escaping (Album.Identity?) -> Void) -> Bool {
        struct Dependency: AlbumSelectionModalDependency {
            let userSettingStorage: UserSettingsStorageProtocol
            let clipCommandService: ClipCommandServiceProtocol
            let clipQueryService: ClipQueryServiceProtocol
            let albumSelectionCompleted: (Album.Identity?) -> Void
        }
        let dependency = Dependency(userSettingStorage: userSettingStorage,
                                    clipCommandService: clipCommandService,
                                    clipQueryService: clipQueryService,
                                    albumSelectionCompleted: completion)
        let state = AlbumSelectionModalState(searchQuery: "",
                                             albums: .init(_values: [:],
                                                           _selectedIds: .init(),
                                                           _displayableIds: .init()),
                                             isCollectionViewDisplaying: false,
                                             isEmptyMessageViewDisplaying: false,
                                             isSearchBarEnabled: false,
                                             alert: nil,
                                             isDismissed: false,
                                             _isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                             _searchStorage: .init())
        let albumAdditionAlertState = TextEditAlertState(id: UUID(),
                                                         title: L10n.albumListViewAlertForAddTitle,
                                                         message: L10n.albumListViewAlertForAddMessage,
                                                         placeholder: L10n.placeholderAlbumName,
                                                         text: "",
                                                         shouldReturn: false,
                                                         isPresenting: false)
        let viewController = AlbumSelectionModalController(state: state,
                                                           albumAdditionAlertState: albumAdditionAlertState,
                                                           dependency: dependency,
                                                           thumbnailLoader: albumThumbnailLoader)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showClipMergeModal(for clips: [Clip], completion: @escaping (Bool) -> Void) -> Bool {
        struct Dependency: ClipMergeViewDependency {
            let router: Router
            let clipCommandService: ClipCommandServiceProtocol
            let clipQueryService: ClipQueryServiceProtocol
            let clipMergeCompleted: (Bool) -> Void
        }
        let dependency = Dependency(router: self,
                                    clipCommandService: clipCommandService,
                                    clipQueryService: clipQueryService,
                                    clipMergeCompleted: completion)
        let state = ClipMergeViewState(items: clips.flatMap({ $0.items }),
                                       tags: [],
                                       alert: nil,
                                       isDismissed: false,
                                       _sourceClipIds: Set(clips.map({ $0.id })))
        let viewController = ClipMergeViewController(state: state,
                                                     dependency: dependency,
                                                     thumbnailLoader: temporaryThumbnailLoader)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showClipEditModal(for clipId: Clip.Identity, completion: ((Bool) -> Void)?) -> Bool {
        let state = ClipEditViewState(clip: .init(id: clipId,
                                                  // 初回は適当な値で埋めておく
                                                  dataSize: 0,
                                                  isHidden: false),
                                      tags: .init(_values: [:], _selectedIds: .init(), _displayableIds: .init()),
                                      items: .init(_values: [:], _selectedIds: .init(), _displayableIds: .init()),
                                      isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                      isItemsEditing: false,
                                      alert: nil,
                                      isDismissed: false)
        let siteUrlEditAlertState = TextEditAlertState(id: UUID(),
                                                       title: L10n.clipPreviewViewAlertForEditSiteUrlTitle,
                                                       message: L10n.clipPreviewViewAlertForEditSiteUrlMessage,
                                                       placeholder: L10n.placeholderUrl,
                                                       text: "",
                                                       shouldReturn: false,
                                                       isPresenting: false)
        let viewController = ClipEditViewController(state: state,
                                                    siteUrlEditAlertState: siteUrlEditAlertState,
                                                    dependency: self,
                                                    thumbnailLoader: temporaryThumbnailLoader)

        guard let topViewController = topViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}
