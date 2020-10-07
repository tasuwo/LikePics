//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
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

        guard let topClipsListViewController = self.factory.makeTopClipsListViewController() else {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Unable to initialize TopClipsListView."))
            return
        }

        guard let tagListViewController = self.factory.makeTagListViewController() else {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Unable to initialize TagListViewController."))
            return
        }

        let albumListViewController = self.factory.makeAlbumListViewController()
        let searchEntryViewController = self.factory.makeSearchEntryViewController()
        let settingsViewController = self.factory.makeSettingsViewController()

        topClipsListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemHome,
                                                             image: UIImage(systemName: "house"),
                                                             tag: 0)
        albumListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemAlbum,
                                                          image: UIImage(systemName: "square.stack"),
                                                          tag: 1)
        tagListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemTag,
                                                        image: UIImage(systemName: "tag"),
                                                        tag: 2)
        searchEntryViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemSearch,
                                                            image: UIImage(systemName: "magnifyingglass"),
                                                            tag: 3)
        settingsViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemSettings,
                                                         image: UIImage(systemName: "gear"),
                                                         tag: 4)

        self.viewControllers = [
            topClipsListViewController,
            tagListViewController,
            albumListViewController,
            searchEntryViewController,
            settingsViewController
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
