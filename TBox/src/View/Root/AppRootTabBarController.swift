//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class AppRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory

    // MARK: - Lifecycle

    init(factory: Factory) {
        self.factory = factory
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let topClipsListViewController = self.factory.makeTopClipsListViewController()
        let albumListViewController = self.factory.makeAlbumListViewController()
        let tagListViewController = self.factory.makeTagListViewController()
        let searchEntryViewController = self.factory.makeSearchEntryViewController()

        // TODO: Localize
        topClipsListViewController.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        albumListViewController.tabBarItem = UITabBarItem(title: "Album", image: UIImage(systemName: "square.stack"), tag: 1)
        tagListViewController.tabBarItem = UITabBarItem(title: "Tags", image: UIImage(systemName: "tag"), tag: 2)
        searchEntryViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 3)

        self.viewControllers = [
            topClipsListViewController,
            tagListViewController,
            albumListViewController,
            searchEntryViewController
        ]
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.updateAppearance()
    }

    // MARK: - Methods

    private func updateAppearance() {
        guard let viewController = self.selectedViewController else {
            self.tabBar.isHidden = false
            return
        }

        guard viewController is TopClipsListViewController
            || (viewController as? UINavigationController)?.viewControllers.contains(where: { $0 is TopClipsListViewController }) ?? false
        else {
            self.tabBar.isHidden = false
            return
        }

        self.tabBar.isHidden = UIDevice.current.orientation.isLandscape
    }
}
