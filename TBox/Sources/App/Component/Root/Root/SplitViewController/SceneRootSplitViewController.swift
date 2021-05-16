//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

class SceneRootSplitViewController: UISplitViewController {
    typealias Factory = ViewControllerFactory
    typealias Store = LikePics.Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency>

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: View

    private var sideBarController: SceneRootSideBarController
    private var compactRootViewController: UITabBarController

    private var detailTopClipListViewController: UIViewController
    private var detailSearchViewController: UIViewController
    private var detailTagListViewController: UIViewController
    private var detailAlbumListViewController: UIViewController
    private var detailSettingViewController: UIViewController

    private var detailViewControllers: [UIViewController] {
        return [
            detailTopClipListViewController,
            detailSearchViewController,
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

    // MARK: Store

    private var clipsIntegrityValidatorStore: Store
    private var subscriptions = Set<AnyCancellable>()

    // MARK: Privates

    private let intent: Intent?
    private let logger: Loggable

    // MARK: - Initializers

    init(factory: Factory,
         clipsIntegrityValidatorStore: Store,
         intent: Intent?,
         logger: Loggable)
    {
        self.factory = factory
        self.clipsIntegrityValidatorStore = clipsIntegrityValidatorStore
        self.intent = intent
        self.logger = logger

        self.sideBarController = SceneRootSideBarController()

        self.compactRootViewController = UITabBarController()

        self.detailTopClipListViewController = SceneRoot.TabBarItem.top.makeViewController(by: factory, intent: intent)
        self.detailSearchViewController = SceneRoot.TabBarItem.search.makeViewController(by: factory, intent: intent)
        self.detailTagListViewController = SceneRoot.TabBarItem.tags.makeViewController(by: factory, intent: intent)
        self.detailAlbumListViewController = SceneRoot.TabBarItem.albums.makeViewController(by: factory, intent: intent)
        self.detailSettingViewController = SceneRoot.TabBarItem.setting.makeViewController(by: factory, intent: intent)

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

        bind(to: clipsIntegrityValidatorStore)
    }
}

// MARK: - Bind

extension SceneRootSplitViewController {
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

extension SceneRootSplitViewController {
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

    private func setSecondaryViewController(for item: SceneRootSideBarController.Item) {
        switch item {
        case .top:
            setViewController(detailTopClipListViewController, for: .secondary)

        case .search:
            setViewController(detailSearchViewController, for: .secondary)

        case .tags:
            setViewController(detailTagListViewController, for: .secondary)

        case .albums:
            setViewController(detailAlbumListViewController, for: .secondary)

        case .setting:
            setViewController(detailSettingViewController, for: .secondary)
        }
    }
}

extension SceneRootSplitViewController: SceneRootSideBarControllerDelegate {
    func appRootSideBarController(_ controller: SceneRootSideBarController, didSelect item: SceneRootSideBarController.Item) {
        setSecondaryViewController(for: item)
    }
}

extension SceneRootSplitViewController: CloudStackLoaderObserver {
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

extension SceneRootSplitViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let previousTraitCollection = previousTraitCollection else { return }
        if previousTraitCollection.horizontalSizeClass != traitCollection.horizontalSizeClass {
            switch traitCollection.horizontalSizeClass {
            case .compact:
                compactRootViewController.setViewControllers(detailViewControllers, animated: false)
                let preferredItem = sideBarController.currentItem.map(to: SceneRoot.TabBarItem.self)
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
                } else if compactRootViewController.selectedViewController === detailSearchViewController {
                    sideBarController.select(.search)
                    setSecondaryViewController(for: .search)
                } else {
                    sideBarController.select(.top)
                    setSecondaryViewController(for: .top)
                }
                compactRootViewController.setViewControllers([], animated: false)
            }
        }
    }
}

extension SceneRootSplitViewController: LoadingViewPresentable {
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

extension SceneRootSplitViewController: SceneRootViewController {
    // MARK: - SceneRootViewController

    var currentViewController: UIViewController? { currentDetailViewController }
}
