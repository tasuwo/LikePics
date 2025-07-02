//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Environment
import UIKit

struct TabBarViewHierarchy {
    // MARK: - Properties

    let tabBarController: UITabBarController
    private let factory: ViewControllerFactory

    // MARK: - Initializers

    init(intent: Intent?, factory: ViewControllerFactory) {
        self.factory = factory
        self.tabBarController = Self.restore(from: intent, by: factory)
    }

    init(tabBarController: UITabBarController, factory: ViewControllerFactory) {
        self.tabBarController = tabBarController
        self.factory = factory
    }
}

// MARK: - State Restoration

extension TabBarViewHierarchy {
    static func restore(from intent: Intent?, by factory: ViewControllerFactory) -> UITabBarController {
        let viewControllers = SceneRoot.TabBarItem.allCases.map {
            $0.makeViewController(from: intent, by: factory)
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers(viewControllers, animated: false)
        tabBarController.selectedIndex = (intent?.selectedTabBarItem ?? .top).rawValue

        return tabBarController
    }
}

// MARK: - Methods

extension TabBarViewHierarchy {
    @MainActor
    static func build(from viewHierarchy: SplitViewHierarchy, by factory: ViewControllerFactory) -> Self {
        let viewControllers: [RestorableViewController] = SceneRoot.TabBarItem.allCases.map {
            let sideBarItem = $0.map(to: SceneRoot.SideBarItem.self)
            let viewController =
                viewHierarchy.detailViewControllers[sideBarItem]?.restore()
                ?? sideBarItem.makeViewController(from: nil, by: factory)
            viewController.tabBarItem = $0.tabBarItem
            return viewController
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers(viewControllers, animated: false)
        tabBarController.selectedIndex = viewHierarchy.currentItem.map(to: SceneRoot.TabBarItem.self).rawValue

        return .init(tabBarController: tabBarController, factory: factory)
    }

    func resolveViewController(at item: SceneRoot.TabBarItem) -> RestorableViewController? {
        return tabBarController.viewControllers?[item.rawValue] as? RestorableViewController
    }

    func resolveCurrentTabBarItem() -> SceneRoot.TabBarItem {
        return SceneRoot.TabBarItem(rawValue: tabBarController.selectedIndex) ?? .top
    }
}
