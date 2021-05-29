//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

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
    static func build(from viewHierarchy: SplitViewHierarchy, by factory: ViewControllerFactory) -> Self {
        fatalError("TODO")
    }

    func resolveCurrentTabBarItem() -> SceneRoot.TabBarItem {
        return SceneRoot.TabBarItem(rawValue: tabBarController.selectedIndex) ?? .top
    }
}
