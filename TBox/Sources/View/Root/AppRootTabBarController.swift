//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class AppRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let integrityViewModel: ClipIntegrityResolvingViewModelType

    // MARK: View

    var loadingView: UIView?
    var loadingLabel: UILabel?

    // MARK: Privates

    let logger: TBoxLoggable
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(factory: Factory,
         integrityViewModel: ClipIntegrityResolvingViewModelType,
         logger: TBoxLoggable = RootLogger.shared)
    {
        self.factory = factory
        self.integrityViewModel = integrityViewModel
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupTabBar()
        self.updateAppearance()

        self.bind(to: integrityViewModel)

        self.integrityViewModel.inputs.didLaunchApp.send(())
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateAppearance()
        }, completion: nil)
    }

    // MARK: - Methods

    // MARK: Bind

    private func bind(to dependency: ClipIntegrityResolvingViewModelType) {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak dependency] _ in dependency?.inputs.sceneDidBecomeActive.send(()) }
            .store(in: &self.subscriptions)

        dependency.outputs.isLoading
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.addLoadingView()
                } else {
                    self?.removeLoadingView()
                }
            }
            .store(in: &self.subscriptions)

        dependency.outputs.loadingTargetIndex
            .combineLatest(dependency.outputs.allLoadingTargetCount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadingTargetIndex, allLoadingTargetCount in
                self?.didStartLoad(at: loadingTargetIndex, in: allLoadingTargetCount)
            }
            .store(in: &self.subscriptions)
    }

    // MARK: TabBar

    private func setupTabBar() {
        guard let topClipsListViewController = self.factory.makeTopClipCollectionViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize TopClipCollectionView."))
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
    }

    // MARK: Appearance

    private func updateAppearance() {
        guard let viewController = self.selectedViewController else {
            self.tabBar.isHidden = false
            return
        }

        guard viewController is TopClipCollectionViewController
            || (viewController as? UINavigationController)?.viewControllers.contains(where: { $0 is TopClipCollectionViewController }) ?? false
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
