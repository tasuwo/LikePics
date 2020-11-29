//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

class AppRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    let logger: TBoxLoggable

    // MARK: - Lifecycle

    init(factory: Factory, logger: TBoxLoggable = RootLogger.shared) {
        self.factory = factory
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let topClipsListViewController = self.factory.makeTopClipsListViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize TopClipsListView."))
            return
        }

        guard let tagListViewController = self.factory.makeTagListViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize TagListViewController."))
            return
        }

        guard let albumListViewController = self.factory.makeAlbumListViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize AlbumListViewController."))
            return
        }

        // let searchEntryViewController = self.factory.makeSearchEntryViewController()
        let settingsViewController = self.factory.makeSettingsViewController()

        self.tabBar.accessibilityIdentifier = "AppRootTabBarController.tabBar"

        topClipsListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemHome,
                                                             image: UIImage(systemName: "house"),
                                                             tag: 0)
        topClipsListViewController.tabBarItem.accessibilityIdentifier = "AppRootTabBarController.tabBarItem.top"
        albumListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemAlbum,
                                                          image: UIImage(systemName: "square.stack"),
                                                          tag: 1)
        albumListViewController.tabBarItem.accessibilityIdentifier = "AppRootTabBarController.tabBarItem.album"
        tagListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemTag,
                                                        image: UIImage(systemName: "tag"),
                                                        tag: 2)
        tagListViewController.tabBarItem.accessibilityIdentifier = "AppRootTabBarController.tabBarItem.tag"
        // searchEntryViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemSearch,
        //                                                     image: UIImage(systemName: "magnifyingglass"),
        //                                                     tag: 3)
        settingsViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemSettings,
                                                         image: UIImage(systemName: "gear"),
                                                         tag: 3)
        settingsViewController.tabBarItem.accessibilityIdentifier = "AppRootTabBarController.tabBarItem.setting"

        self.viewControllers = [
            topClipsListViewController,
            tagListViewController,
            albumListViewController,
            // searchEntryViewController,
            settingsViewController
        ]

        self.updateAppearance()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateAppearance()
        }, completion: nil)
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

        self.tabBar.isHidden = self.traitCollection.verticalSizeClass == .compact
    }
}

extension AppRootTabBarController: CloudStackLoaderObserver {
    // MARK: - CloudStackLoaderObserver

    func didAccountChanged(_ loader: CloudStackLoader) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: L10n.errorIcloudAccountChangedTitle,
                                                    message: L10n.errorIcloudAccountChangedMessage,
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.confirmAlertOk,
                                         style: .default,
                                         handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func didDisabledICloudSyncByUnavailableAccount(_ loader: CloudStackLoader) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: L10n.errorIcloudUnavailableTitle,
                                                    message: L10n.errorIcloudUnavailableMessage,
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.confirmAlertOk,
                                         style: .default,
                                         handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
