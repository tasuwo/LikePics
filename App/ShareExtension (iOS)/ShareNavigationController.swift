//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import ShareExtensionFeature
import UIKit

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {
    private var factory: DependencyContainer!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        UIView.appearance().tintColor = UIColor(named: "like_pics_red")
        UIBarButtonItem.appearance().tintColor = UIColor(named: "like_pics_red")
        UISwitch.appearance().onTintColor = UIColor(named: "like_pics_switch")

        do {
            self.factory = try DependencyContainer(rootViewController: self)
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
