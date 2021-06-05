//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import ForestKit
import TBoxUIKit
import UIKit

class SceneRootTabBarController: UITabBarController {
    typealias Factory = ViewControllerFactory
    typealias Store = ForestKit.Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency>

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
    private let intent: Intent?

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
            .debounce(for: 1, scheduler: DispatchQueue.main)
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
        tabBar.accessibilityIdentifier = "SceneRootTabBarController.tabBar"

        let viewControllers = SceneRoot.TabBarItem.allCases.map {
            $0.makeViewController(from: intent, by: factory)
        }

        setViewControllers(viewControllers, animated: false)
        selectedIndex = (intent?.selectedTabBarItem ?? .top).rawValue
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

    func select(_ barItem: SceneRoot.BarItem) {
        selectedIndex = barItem.tabBarItem.rawValue
    }
}
