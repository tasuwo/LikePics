//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

enum SceneRootViewLayout {
    case split(SplitViewHierarchy)
    case compact(TabBarViewHierarchy)
}

// MARK: - Initializers

extension SceneRootViewLayout {
    init(horizontalSizeClass: UIUserInterfaceSizeClass,
         intent: Intent?,
         factory: ViewControllerFactory)
    {
        switch horizontalSizeClass {
        case .compact:
            self = .compact(.init(intent: intent, factory: factory))

        default:
            self = .split(.init(intent: intent, factory: factory))
        }
    }
}

// MARK: - Properties

extension SceneRootViewLayout {
    var topViewController: UIViewController? {
        switch self {
        case let .compact(viewHierarchy):
            return viewHierarchy.tabBarController.selectedViewController

        case let .split(viewHierarchy):
            return viewHierarchy.currentDetailViewController()
        }
    }

    var tabBarItem: SceneRoot.TabBarItem {
        switch self {
        case let .compact(viewHierarchy):
            return viewHierarchy.resolveCurrentTabBarItem()

        case let .split(viewHierarchy):
            return viewHierarchy.currentItem.map(to: SceneRoot.TabBarItem.self)
        }
    }

    var sideBarItem: SceneRoot.SideBarItem {
        switch self {
        case let .compact(viewHierarchy):
            let tabBarItem = viewHierarchy.resolveCurrentTabBarItem()
            return tabBarItem.map(to: SceneRoot.SideBarItem.self)

        case let .split(viewHierarchy):
            return viewHierarchy.currentItem
        }
    }
}

// MARK: - Methods

extension SceneRootViewLayout {
    @MainActor
    func applying(horizontalSizeClass: UIUserInterfaceSizeClass, factory: ViewControllerFactory) -> Self? {
        switch (self, horizontalSizeClass) {
        case let (.split(viewHierarchy), .compact):
            return .compact(.build(from: viewHierarchy, by: factory))

        case let (.compact(viewHierarchy), .regular):
            return .split(.build(from: viewHierarchy, by: factory))

        default:
            return nil
        }
    }
}
