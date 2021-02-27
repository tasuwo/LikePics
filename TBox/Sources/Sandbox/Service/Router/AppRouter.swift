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

    @discardableResult
    private func showCollectionView(by query: ClipListQuery, for context: ClipCollection.SearchContext) -> Bool {
        guard let rootViewController = self.rootViewController else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: """
            Failed to open SearchResultView.
            """))
            return false
        }

        let innerViewModel = ClipCollectionViewModel(clipService: _clipCommandService,
                                                     queryService: _clipQueryService,
                                                     imageQueryService: imageQueryService,
                                                     logger: logger)
        let viewModel = SearchResultViewModel(context: context,
                                              query: query,
                                              settingStorage: _userSettingStorage,
                                              logger: logger,
                                              viewModel: innerViewModel)

        let context = ClipCollection.Context(isAlbum: false)

        let navigationItemsViewModel = ClipCollectionNavigationBarViewModel(context: context)
        let navigationItemsProvider = ClipCollectionNavigationBarProvider(viewModel: navigationItemsViewModel)

        let toolBarItemsViewModel = ClipCollectionToolBarViewModel(context: context)
        let toolBarItemsProvider = ClipCollectionToolBarProvider(viewModel: toolBarItemsViewModel)

        let viewController = SearchResultViewController(factory: self,
                                                        viewModel: viewModel,
                                                        clipCollectionProvider: ClipCollectionProvider(thumbnailLoader: clipThumbnailLoader),
                                                        navigationItemsProvider: navigationItemsProvider,
                                                        toolBarItemsProvider: toolBarItemsProvider,
                                                        menuBuilder: ClipCollectionMenuBuilder(storage: _userSettingStorage))

        rootViewController.currentDetailViewController?.show(viewController, sender: self)

        return true
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
        let query: ClipListQuery
        switch _clipQueryService.queryUncategorizedClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            RootLogger.shared.write(ConsoleLog(level: .error, message: """
            Failed to open SearchResultView for uncategorized clips. (\(error.rawValue))
            """))
            return false
        }
        return showCollectionView(by: query, for: .tag(.uncategorized))
    }

    func showClipCollectionView(for tag: Tag) -> Bool {
        let query: ClipListQuery
        switch _clipQueryService.queryClips(tagged: tag.id) {
        case let .success(result):
            query = result

        case let .failure(error):
            RootLogger.shared.write(ConsoleLog(level: .error, message: """
            Failed to open SearchResultView for tag \(tag.id). (\(error.rawValue))
            """))
            return false
        }
        return showCollectionView(by: query, for: .tag(.categorized(tag)))
    }

    func showClipCollectionView(for albumId: Album.Identity) -> Bool {
        // TODO:
        print(#function)
        return false
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

        let state = TagSelectionModalState(isDismissed: false,
                                           tags: .init(_values: [:],
                                                       _selectedIds: selections,
                                                       _displayableIds: .init()),
                                           searchQuery: "",
                                           isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                           isCollectionViewDisplaying: false,
                                           isEmptyMessageViewDisplaying: false,
                                           isSearchBarEnabled: false,
                                           alert: nil,
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

    func showAlbumSelectionModal(completion: ((Album.Identity?) -> Void)?) -> Bool {
        let state = AlbumSelectionModalState(searchQuery: "",
                                             isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                             isCollectionViewDisplaying: false,
                                             isEmptyMessageViewDisplaying: false,
                                             isSearchBarEnabled: false,
                                             alert: nil,
                                             _albums: [:],
                                             _filteredAlbumIds: .init(),
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
                                                           dependency: self,
                                                           thumbnailLoader: albumThumbnailLoader,
                                                           completion: completion)

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
        let viewController = NewClipMergeViewController(state: state,
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
        let viewController = NewClipEditViewController(state: state,
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
