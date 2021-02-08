//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UINavigationController: Restorable {
    func restore() -> UIViewController {
        let navigationController = UINavigationController()
        navigationController.tabBarItem = tabBarItem

        for viewController in viewControllers {
            guard let restorable = viewController as? Restorable else { continue }
            navigationController.pushViewController(restorable.restore(), animated: false)
        }

        return navigationController
    }
}
