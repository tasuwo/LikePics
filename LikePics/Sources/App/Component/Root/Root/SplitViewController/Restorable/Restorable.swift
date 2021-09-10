//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

typealias RestorableViewController = UIViewController & Restorable

protocol Restorable {
    func restore() -> RestorableViewController
}

extension UINavigationController: Restorable {
    // MARK: - Restorable

    func restore() -> RestorableViewController {
        let navigationController = UINavigationController(nibName: nil, bundle: nil)
        navigationController.tabBarItem = tabBarItem

        viewControllers
            .compactMap { $0 as? Restorable }
            .forEach { navigationController.pushViewController($0.restore(), animated: false) }

        return navigationController
    }
}
