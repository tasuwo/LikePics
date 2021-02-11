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

    private func showCollectionView(by query: ClipListQuery, for context: ClipCollection.SearchContext) {
        guard let rootViewController = self.rootViewController else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: """
            Failed to open SearchResultView.
            """))
            return
        }

        let innerViewModel = ClipCollectionViewModel(clipService: clipCommandService,
                                                     queryService: clipQueryService,
                                                     imageQueryService: imageQueryService,
                                                     logger: logger)
        let viewModel = SearchResultViewModel(context: context,
                                              query: query,
                                              settingStorage: userSettingsStorage,
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
                                                        menuBuilder: ClipCollectionMenuBuilder(storage: userSettingsStorage))

        rootViewController.currentDetailViewController?.show(viewController, sender: self)
    }
}

extension DependencyContainer: Router {
    // MARK: - Router

    func showUncategorizedClipCollectionView() {
        let query: ClipListQuery
        switch self.clipQueryService.queryUncategorizedClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            RootLogger.shared.write(ConsoleLog(level: .error, message: """
            Failed to open SearchResultView for uncategorized clips. (\(error.rawValue))
            """))
            return
        }
        self.showCollectionView(by: query, for: .tag(.uncategorized))
    }

    func showClipCollectionView(for tag: Tag) {
        let query: ClipListQuery
        switch clipQueryService.queryClips(tagged: tag.id) {
        case let .success(result):
            query = result

        case let .failure(error):
            RootLogger.shared.write(ConsoleLog(level: .error, message: """
            Failed to open SearchResultView for tag \(tag.id). (\(error.rawValue))
            """))
            return
        }
        self.showCollectionView(by: query, for: .tag(.categorized(tag)))
    }
}
