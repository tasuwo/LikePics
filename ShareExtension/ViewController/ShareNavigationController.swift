//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {
    private let factory = DependencyContainer()

    // MARK: - Lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.setViewControllers(
            [
                self.factory.makeClipTargetCollectionViewController()
            ],
            animated: false
        )
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
