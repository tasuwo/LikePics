//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class AppRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory

    init(factory: Factory) {
        self.factory = factory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let clipViewController = factory.makeClipsViewController()

        clipViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)

        self.viewControllers = [
            self.factory.makeClipPreviewTransitionableNavigationController(root: clipViewController)
        ]
    }
}
