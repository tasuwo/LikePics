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

    func showClipPreviewView(for clipId: Clip.Identity) -> Bool {
        guard let viewController = self.makeClipPreviewPageViewController(clipId: clipId) else { return false }
        guard let detailViewController = rootViewController?.currentDetailViewController else { return false }
        detailViewController.present(viewController, animated: true, completion: nil)
        return true
    }

    func showTagSelectionModal(selections: Set<Tag.Identity>, completion: ((Set<Tag.Identity>?) -> Void)?) -> Bool {
        let state = TagSelectionModalState(searchQuery: "",
                                           initialSelections: selections,
                                           selections: .init(),
                                           isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                           isCollectionViewDisplaying: false,
                                           isEmptyMessageViewDisplaying: false,
                                           isSearchBarEnabled: false,
                                           alert: nil,
                                           _tags: [:],
                                           _filteredTagIds: .init(),
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
                                                         dependency: self,
                                                         completion: completion)

        guard let detailViewController = rootViewController?.currentDetailViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        detailViewController.present(navigationViewController, animated: true, completion: nil)

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

        guard let detailViewController = rootViewController?.currentDetailViewController else { return false }
        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        detailViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }

    func showShareModal(from: ClipCollection.ShareSource, clips: Set<Clip.Identity>, completion: ((Bool) -> Void)?) -> Bool {
        // TODO:
        print(#function)
        return false
    }

    func showClipMergeModal(for clips: [Clip], completion: ((Bool) -> Void)?) -> Bool {
        // TODO:
        print(#function)
        return false
    }

    func showClipEditModal(for clip: Clip.Identity, completion: ((Bool) -> Void)?) -> Bool {
        // TODO:
        print(#function)
        return false
    }
}
