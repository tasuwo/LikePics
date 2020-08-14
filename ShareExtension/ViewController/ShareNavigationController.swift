//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {
    private let factory = DependencyContainer()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true

        self.setViewControllers(
            [
                self.factory.makeShareNavigationRootViewController()
            ],
            animated: false
        )
    }
}
