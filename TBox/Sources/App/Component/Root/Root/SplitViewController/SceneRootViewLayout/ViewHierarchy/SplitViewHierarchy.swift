//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable force_unwrapping

import UIKit

struct SplitViewHierarchy {
    // MARK: - Properties

    let currentItem: SceneRoot.SideBarItem
    let detailViewControllers: [SceneRoot.SideBarItem: RestorableViewController]
    private let factory: ViewControllerFactory

    // MARK: - Initializers

    init(intent: Intent?, factory: ViewControllerFactory) {
        let currentItem = intent?.selectedSideBarItem ?? .top
        self.currentItem = currentItem
        self.detailViewControllers = [currentItem: currentItem.makeViewController(from: intent, by: factory)]
        self.factory = factory
    }

    private init(item: SceneRoot.SideBarItem,
                 detailViewControllers: [SceneRoot.SideBarItem: RestorableViewController],
                 factory: ViewControllerFactory)
    {
        self.currentItem = item
        self.detailViewControllers = detailViewControllers
        self.factory = factory
    }
}

// MARK: - Methods

extension SplitViewHierarchy {
    static func build(from viewHierarchy: TabBarViewHierarchy, by factory: ViewControllerFactory) -> Self {
        let viewControllers = SceneRoot.TabBarItem.allCases.reduce(into: [SceneRoot.SideBarItem: RestorableViewController]()) { dict, item in
            let sideBarItem = item.map(to: SceneRoot.SideBarItem.self)
            let viewController = viewHierarchy.resolveViewController(at: item)?.restore()
                ?? sideBarItem.makeViewController(from: nil, by: factory)
            dict[sideBarItem] = viewController
        }
        return .init(item: viewHierarchy.resolveCurrentTabBarItem().map(to: SceneRoot.SideBarItem.self),
                     detailViewControllers: viewControllers,
                     factory: factory)
    }

    func currentDetailViewController() -> UIViewController {
        return detailViewControllers[currentItem]!
    }

    func selecting(_ item: SceneRoot.SideBarItem) -> Self? {
        guard item != currentItem else { return nil }

        var nextDetailViewControllers = detailViewControllers
        if detailViewControllers[item] == nil {
            let viewController = item.makeViewController(from: nil, by: factory)
            nextDetailViewControllers[item] = viewController
        }

        return .init(item: item,
                     detailViewControllers: nextDetailViewControllers,
                     factory: factory)
    }
}
