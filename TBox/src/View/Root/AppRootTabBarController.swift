//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
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

        let topClipsListViewController = self.factory.makeTopClipsListViewController()
        let albumViewController = self.factory.makeAlbumListViewController()
        let searchEntryViewController = self.factory.makeSearchEntryViewController()

        topClipsListViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)
        albumViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .bookmarks, tag: 1)
        searchEntryViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 2)

        self.viewControllers = [
            topClipsListViewController,
            albumViewController,
            searchEntryViewController
        ]
    }
}
