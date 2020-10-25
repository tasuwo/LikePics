//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var factory: DependencyContainer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            self.factory = try DependencyContainer()
        } catch {
            fatalError("Unable to start Share Extension.")
        }

        self.navigationItem.hidesBackButton = true

        self.setViewControllers(
            [
                self.factory.makeShareNavigationRootViewController()
            ],
            animated: false
        )
    }
}
