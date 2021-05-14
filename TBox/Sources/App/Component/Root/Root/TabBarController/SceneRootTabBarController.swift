//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class SceneRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory
    typealias Store = LikePics.Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency>

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: View

    private var _loadingView: UIView?
    private var _loadingLabel: UILabel?

    // MARK: Store

    private var clipsIntegrityValidatorStore: Store
    private var subscriptions = Set<AnyCancellable>()

    // MARK: Privates

    private let logger: Loggable

    // MARK: - Initializers

    init(factory: Factory,
         clipsIntegrityValidatorStore: Store,
         logger: Loggable)
    {
        self.factory = factory
        self.clipsIntegrityValidatorStore = clipsIntegrityValidatorStore
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTabBar()

        bind(to: clipsIntegrityValidatorStore)
    }
}

// MARK: - Bind

extension SceneRootTabBarController {
    private func bind(to store: Store) {
        store.state
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .bind(\.state.isLoading) { [weak self] isLoading in
                if isLoading {
                    self?.addLoadingView()
                } else {
                    self?.removeLoadingView()
                }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.state) { [weak self] state in
                switch state {
                case let .loading(currentIndex: index, counts: counts):
                    self?.didStartLoad(at: index, in: counts)

                case .stopped:
                    self?.didStartLoad(at: nil, in: nil)
                }
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Configuration

extension SceneRootTabBarController {
    private func configureTabBar() {
        guard let topClipsListViewController = self.factory.makeTopClipCollectionViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize TopClipCollectionView."))
            return
        }

        guard let tagListViewController = self.factory.makeTagCollectionViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize TagListViewController."))
            return
        }

        guard let albumListViewController = self.factory.makeAlbumListViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize AlbumListViewController."))
            return
        }

        guard let searchEntryViewController = self.factory.makeSearchViewController() else {
            self.logger.write(ConsoleLog(level: .critical, message: "Unable to initialize SearchEntryViewController."))
            return
        }

        let settingsViewController = self.factory.makeSettingsViewController()

        self.tabBar.accessibilityIdentifier = "SceneRootTabBarController.tabBar"

        topClipsListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemHome,
                                                             image: UIImage(systemName: "house"),
                                                             tag: 0)
        topClipsListViewController.tabBarItem.accessibilityIdentifier = "SceneRootTabBarController.tabBarItem.top"

        searchEntryViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemSearch,
                                                            image: UIImage(systemName: "magnifyingglass"),
                                                            tag: 2)
        searchEntryViewController.tabBarItem.accessibilityIdentifier = "SceneRootTabBarController.tabBarItem.search"

        tagListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemTag,
                                                        image: UIImage(systemName: "tag"),
                                                        tag: 3)
        tagListViewController.tabBarItem.accessibilityIdentifier = "SceneRootTabBarController.tabBarItem.tag"

        albumListViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemAlbum,
                                                          image: UIImage(systemName: "square.stack"),
                                                          tag: 4)
        albumListViewController.tabBarItem.accessibilityIdentifier = "SceneRootTabBarController.tabBarItem.album"

        settingsViewController.tabBarItem = UITabBarItem(title: L10n.appRootTabItemSettings,
                                                         image: UIImage(systemName: "gear"),
                                                         tag: 5)
        settingsViewController.tabBarItem.accessibilityIdentifier = "SceneRootTabBarController.tabBarItem.setting"

        self.viewControllers = [
            topClipsListViewController,
            searchEntryViewController,
            tagListViewController,
            albumListViewController,
            settingsViewController
        ]
    }
}

extension SceneRootTabBarController: CloudStackLoaderObserver {
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

extension SceneRootTabBarController: LoadingViewPresentable {
    // MARK: - LoadingViewPresentable

    var loadingView: UIView? {
        get { _loadingView }
        set { _loadingView = newValue }
    }

    var loadingLabel: UILabel? {
        get { _loadingLabel }
        set { _loadingLabel = newValue }
    }
}

extension SceneRootTabBarController: SceneRootViewController {
    // MARK: - SceneRootViewController

    var currentViewController: UIViewController? { selectedViewController }
}
