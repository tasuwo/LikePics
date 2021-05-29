//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol Restorable {
    func restore() -> UIViewController
}

extension UINavigationController: Restorable {
    // MARK: - Restorable

    func restore() -> UIViewController {
        let navigationController = UINavigationController(nibName: nil, bundle: nil)
        navigationController.tabBarItem = tabBarItem

        viewControllers
            .compactMap { $0 as? Restorable }
            .forEach { navigationController.pushViewController($0.restore(), animated: false) }

        return navigationController
    }
}
