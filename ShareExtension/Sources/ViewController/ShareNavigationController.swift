//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import LikePicsUIKit
import UIKit

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {
    private var factory: DependencyContainer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        UIView.appearance().tintColor = Asset.Color.likePicsRed.color
        UIBarButtonItem.appearance().tintColor = Asset.Color.likePicsRed.color

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
