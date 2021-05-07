//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

class AppRootSplitViewController: UISplitViewController {
    typealias Factory = ViewControllerFactory

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let integrityViewModel: ClipIntegrityResolvingViewModelType

    // MARK: View

    private var sideBarController: AppRootSideBarController
    private var compactRootViewController: UITabBarController

    private var detailTopClipListViewController: UIViewController
    private var detailTagListViewController: UIViewController
    private var detailAlbumListViewController: UIViewController
    private var detailSettingViewController: UIViewController

    private var detailViewControllers: [UIViewController] {
        return [
            detailTopClipListViewController,
            detailTagListViewController,
            detailAlbumListViewController,
            detailSettingViewController
        ]
    }

    var currentDetailViewController: UIViewController? {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            return compactRootViewController.selectedViewController

        default:
            return viewController(for: .secondary)
        }
    }

    private var _loadingView: UIView?
    private var _loadingLabel: UILabel?

    // MARK: Privates

    private let logger: Loggable
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Initializers

    init(factory: Factory,
         integrityViewModel: ClipIntegrityResolvingViewModelType,
         logger: Loggable = RootLogger.shared)
    {
        self.factory = factory
        self.integrityViewModel = integrityViewModel
        self.logger = logger

        self.sideBarController = AppRootSideBarController()

        self.compactRootViewController = UITabBarController()

        self.detailTopClipListViewController = AppRoot.TabBarItem.top.makeViewController(by: factory)
        self.detailTagListViewController = AppRoot.TabBarItem.tags.makeViewController(by: factory)
        self.detailAlbumListViewController = AppRoot.TabBarItem.albums.makeViewController(by: factory)
        self.detailSettingViewController = AppRoot.TabBarItem.setting.makeViewController(by: factory)

        super.init(style: .doubleColumn)

        addChild(sideBarController)
        setViewController(sideBarController, for: .primary)
        sideBarController.delegate = self

        addChild(compactRootViewController)
        setViewController(compactRootViewController, for: .compact)

        detailViewControllers.forEach { addChild($0) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        applyInitialValues()

        bind(to: integrityViewModel)

        integrityViewModel.inputs.didLaunchApp.send(())
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
}

// MARK: Configuration

extension AppRootSplitViewController {
    private func applyInitialValues() {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            compactRootViewController.setViewControllers(detailViewControllers, animated: false)
            compactRootViewController.selectedIndex = 0
            // HACK: 初期値がcompactだった場合、expand時に不正な状態にならないよう、
            //       空のViewControllerを配置しておく
            setViewController(UIViewController(), for: .secondary)

        default:
            setSecondaryViewController(for: .top)
        }
    }

    private func setSecondaryViewController(for item: AppRootSideBarController.Item) {
        switch item {
        case .top:
            setViewController(detailTopClipListViewController, for: .secondary)

        case .tags:
            setViewController(detailTagListViewController, for: .secondary)

        case .albums:
            setViewController(detailAlbumListViewController, for: .secondary)

        case .setting:
            setViewController(detailSettingViewController, for: .secondary)
        }
    }
}

extension AppRootSplitViewController: AppRootSideBarControllerDelegate {
    func appRootSideBarController(_ controller: AppRootSideBarController, didSelect item: AppRootSideBarController.Item) {
        setSecondaryViewController(for: item)
    }
}

extension AppRootSplitViewController: CloudStackLoaderObserver {
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

extension AppRootSplitViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let previousTraitCollection = previousTraitCollection else { return }
        if previousTraitCollection.horizontalSizeClass != traitCollection.horizontalSizeClass {
            switch traitCollection.horizontalSizeClass {
            case .compact:
                compactRootViewController.setViewControllers(detailViewControllers, animated: false)
                let preferredItem = sideBarController.currentItem.map(to: AppRoot.TabBarItem.self)
                compactRootViewController.selectedIndex = preferredItem.next.rawValue
                compactRootViewController.selectedIndex = preferredItem.rawValue

            default:
                if compactRootViewController.selectedViewController === detailSettingViewController {
                    sideBarController.select(.setting)
                    setSecondaryViewController(for: .setting)
                } else if compactRootViewController.selectedViewController === detailTagListViewController {
                    sideBarController.select(.tags)
                    setSecondaryViewController(for: .tags)
                } else if compactRootViewController.selectedViewController === detailAlbumListViewController {
                    sideBarController.select(.albums)
                    setSecondaryViewController(for: .albums)
                } else {
                    sideBarController.select(.top)
                    setSecondaryViewController(for: .top)
                }
                compactRootViewController.setViewControllers([], animated: false)
            }
        }
    }
}

extension AppRootSplitViewController: LoadingViewPresentable {
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

extension AppRootSplitViewController: AppRootViewController {
    // MARK: - AppRootViewController

    var currentViewController: UIViewController? { currentDetailViewController }
}
