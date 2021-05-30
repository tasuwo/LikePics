//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

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
                return "SceneRootTabBarController.tabBarItem.top"

            case .search:
                return "SceneRootTabBarController.tabBarItem.search"

            case .tags:
                return "SceneRootTabBarController.tabBarItem.tag"

            case .albums:
                return "SceneRootTabBarController.tabBarItem.album"

            case .setting:
                return "SceneRootTabBarController.tabBarItem.setting"
            }
        }

        func makeViewController(from intent: Intent?, by factory: ViewControllerFactory) -> RestorableViewController {
            let viewController: RestorableViewController
            switch self {
            case .top:
                if let homeViewState = intent?.homeViewState {
                    viewController = factory.makeClipCollectionViewController(homeViewState)
                } else {
                    viewController = factory.makeClipCollectionViewController(from: .all)
                }
                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.tabBarItem = tabBarItem
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

            if case let .clips(state, preview: clipId) = intent,
               state.clipCollectionState.source.mapToTabBarItem() == self
            {
                let clipCollectionViewController = factory.makeClipCollectionViewController(from: state.clipCollectionState.source)
                viewController.show(clipCollectionViewController, sender: nil)

                if let clipId = clipId {
                    let previewPageViewController = factory.makeClipPreviewPageViewController(for: clipId)
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

private extension ClipCollection.Source {
    func mapToTabBarItem() -> SceneRoot.TabBarItem {
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
