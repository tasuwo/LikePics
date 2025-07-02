//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Environment
import UIKit

extension SceneRoot {
    enum TabBarItem: Int, CaseIterable {
        case top
        case search
        case tags
        case albums
        case setting

        var next: TabBarItem {
            guard let nextItem = TabBarItem(rawValue: rawValue + 1) else {
                return .top
            }
            return nextItem
        }

        var image: UIImage {
            switch self {
            case .top:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "house")!

            case .search:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "magnifyingglass")!

            case .tags:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "tag")!

            case .albums:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "square.stack")!

            case .setting:
                // swiftlint:disable:next force_unwrapping
                return UIImage(systemName: "gear")!
            }
        }

        var title: String {
            switch self {
            case .top:
                return L10n.appRootTabItemHome

            case .search:
                return L10n.appRootTabItemSearch

            case .tags:
                return L10n.appRootTabItemTag

            case .albums:
                return L10n.appRootTabItemAlbum

            case .setting:
                return L10n.appRootTabItemSettings
            }
        }

        var tabBarItem: UITabBarItem {
            let tabBarItem = UITabBarItem(title: title, image: image, tag: rawValue)
            tabBarItem.accessibilityIdentifier = accessibilityIdentifier
            return tabBarItem
        }

        var accessibilityIdentifier: String {
            switch self {
            case .top:
                return "SceneRoot.TabBarItem.top"

            case .search:
                return "SceneRoot.TabBarItem.search"

            case .tags:
                return "SceneRoot.TabBarItem.tag"

            case .albums:
                return "SceneRoot.TabBarItem.album"

            case .setting:
                return "SceneRoot.TabBarItem.setting"
            }
        }

        func makeViewController(from intent: Intent?, by factory: ViewControllerFactory) -> RestorableViewController {
            let viewController: RestorableViewController
            switch self {
            case .top:
                let rootViewController: RestorableViewController & ViewLazyPresentable
                if let homeViewState = intent?.homeViewState {
                    rootViewController = factory.makeClipCollectionViewController(homeViewState)
                } else {
                    rootViewController = factory.makeClipCollectionViewController(from: .all)
                }
                let navigationController = UINavigationController(rootViewController: rootViewController)
                navigationController.tabBarItem = tabBarItem

                if case let .clips(state, preview: indexPath) = intent,
                    state.clipCollectionState.source.mapToTabBarItem() == self
                {
                    if let indexPath = indexPath {
                        let previewPageViewController = factory.makeClipPreviewPageViewController(
                            clips: [],
                            query: .clips(state.clipCollectionState.source),
                            indexPath: indexPath
                        )
                        rootViewController.presentAfterLoad(previewPageViewController, animated: false, completion: nil)
                    }
                }

                return navigationController

            case .search:
                // swiftlint:disable:next force_unwrapping
                viewController = factory.makeSearchViewController(intent?.searchViewState)!

            case .tags:
                // swiftlint:disable:next force_unwrapping
                viewController = factory.makeTagCollectionViewController(intent?.tagCollectionViewState)!

            case .albums:
                // swiftlint:disable:next force_unwrapping
                viewController = factory.makeAlbumListViewController(intent?.albumLitViewState)!

            case .setting:
                viewController = factory.makeSettingsViewController(intent?.settingsViewState)
            }

            if case let .clips(state, preview: indexPath) = intent,
                state.clipCollectionState.source.mapToTabBarItem() == self
            {
                let clipCollectionViewController = factory.makeClipCollectionViewController(from: state.clipCollectionState.source)
                viewController.show(clipCollectionViewController, sender: nil)

                if let indexPath = indexPath {
                    let previewPageViewController = factory.makeClipPreviewPageViewController(
                        clips: [],
                        query: .clips(state.clipCollectionState.source),
                        indexPath: indexPath
                    )
                    clipCollectionViewController.presentAfterLoad(previewPageViewController, animated: false, completion: nil)
                }
            }

            viewController.tabBarItem = tabBarItem
            return viewController
        }

        func map(to: SceneRoot.SideBarItem.Type) -> SceneRoot.SideBarItem {
            switch self {
            case .top:
                return .top

            case .search:
                return .search

            case .tags:
                return .tags

            case .albums:
                return .albums

            case .setting:
                return .setting
            }
        }
    }
}

extension ClipCollection.Source {
    fileprivate func mapToTabBarItem() -> SceneRoot.TabBarItem {
        switch self {
        case .all:
            return .top

        case .uncategorized, .tag:
            return .tags

        case .album:
            return .albums

        case .search:
            return .search
        }
    }
}
