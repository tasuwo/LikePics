//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension AppRoot {
    enum SideBarItem: Int, CaseIterable {
        case top
        case search
        case tags
        case albums
        case setting

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

        func map(to: AppRoot.TabBarItem.Type) -> AppRoot.TabBarItem {
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
