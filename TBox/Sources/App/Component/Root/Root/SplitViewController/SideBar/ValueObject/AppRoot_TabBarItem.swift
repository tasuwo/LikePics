//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension AppRoot {
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

        var image: UIImage? {
            switch self {
            case .top:
                return UIImage(systemName: "house")

            case .search:
                return UIImage(systemName: "magnifyingglass")

            case .tags:
                return UIImage(systemName: "tag")

            case .albums:
                return UIImage(systemName: "square.stack")

            case .setting:
                return UIImage(systemName: "gear")
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
            UITabBarItem(title: title, image: image, tag: rawValue)
        }

        var accessibilityIdentifier: String {
            switch self {
            case .top:
                return "AppRootTabBarController.tabBarItem.top"

            case .search:
                return "AppRootTabBarController.tabBarItem.search"

            case .tags:
                return "AppRootTabBarController.tabBarItem.tag"

            case .albums:
                return "AppRootTabBarController.tabBarItem.album"

            case .setting:
                return "AppRootTabBarController.tabBarItem.setting"
            }
        }

        func makeViewController(by factory: ViewControllerFactory) -> UIViewController {
            let viewController: UIViewController
            switch self {
            case .top:
                // swiftlint:disable:next identifier_name
                guard let vc = factory.makeTopClipCollectionViewController() else {
                    fatalError("Unable to initialize TopClipCollectionView.")
                }
                viewController = vc

            case .search:
                // swiftlint:disable:next identifier_name
                guard let vc = factory.makeSearchViewController() else {
                    fatalError("Unable to initialize SearchEntryViewController.")
                }
                viewController = vc

            case .tags:
                // swiftlint:disable:next identifier_name
                guard let vc = factory.makeTagCollectionViewController() else {
                    fatalError("Unable to initialize TagListViewController.")
                }
                viewController = vc

            case .albums:
                // swiftlint:disable:next identifier_name
                guard let vc = factory.makeAlbumListViewController() else {
                    fatalError("Unable to initialize AlbumListViewController.")
                }
                viewController = vc

            case .setting:
                viewController = factory.makeSettingsViewController()
            }

            viewController.tabBarItem = tabBarItem
            viewController.tabBarItem.accessibilityIdentifier = accessibilityIdentifier

            return viewController
        }

        func map(to: AppRoot.SideBarItem.Type) -> AppRoot.SideBarItem {
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
