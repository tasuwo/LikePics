//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
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

    private func makeClipCollectionView(from source: ClipCollectionState.Source) -> UIViewController {
        let state = ClipCollectionState(title: nil,
                                        selections: .init(),
                                        isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                        operation: .none,
                                        isEmptyMessageViewDisplaying: false,
                                        isCollectionViewDisplaying: false,
                                        alert: nil,
                                        source: source,
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
        guard let viewController = self.makeClipPreviewPageViewController(clipId: clipId) else { return false }
        guard let detailViewController = rootViewController?.currentDetailViewController else { return false }
        detailViewController.present(viewController, animated: true, completion: nil)
        return true
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

    func showShareModal(from: ClipCollection.ShareSource, clips: Set<Clip.Identity>, completion: ((Bool) -> Void)?) -> Bool {
        // TODO:
        print(#function)
        return false
    }

    func showClipMergeModal(for clips: [Clip], completion: @escaping (Bool) -> Void) -> Bool {
        struct Dependency: ClipMergeViewDependency {
            let router: Router
            let clipCommandService: ClipCommandServiceProtocol
            let clipMergeCompleted: (Bool) -> Void
        }
        let dependency = Dependency(router: self,
                                    clipCommandService: clipCommandService,
                                    clipMergeCompleted: completion)

        let tags: [Tag]
        switch clipQueryService.readClipAndTags(for: clips.map({ $0.id })) {
        case let .success((_, fetchedTags)):
            tags = fetchedTags

        case .failure:
            return false
        }

        let state = ClipMergeViewState(items: clips.flatMap({ $0.items }),
                                       tags: tags,
                                       alert: nil,
                                       sourceClipIds: Set(clips.map({ $0.id })),
                                       isDismissed: false)
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
