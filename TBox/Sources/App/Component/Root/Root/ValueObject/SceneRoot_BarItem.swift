//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension SceneRoot {
    enum BarItem: Int, CaseIterable {
        case top
        case search
        case tags
        case albums
        case setting
    }
}

extension SceneRoot.BarItem {
    var tabBarItem: SceneRoot.TabBarItem {
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

    var sideBarItem: SceneRoot.SideBarItem {
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
