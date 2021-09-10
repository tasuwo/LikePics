//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import ForestKit
import UIKit

class SceneRootSplitViewController: UISplitViewController {
    typealias Factory = ViewControllerFactory
    typealias Store = ForestKit.Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency>

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: View

    private var sideBarController: SceneRootSideBarController!
    private let compactBaseViewController = UIViewController()
    private let secondaryBaseViewController = UIViewController()
    private var layoutProvider: SceneRootViewLayoutProvider!

    var currentDetailViewController: UIViewController? { layoutProvider.currentTopViewController }

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
        super.init(style: .doubleColumn)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        guard newCollection.horizontalSizeClass == .regular else { return }
        layoutProvider?.apply(horizontalSizeClass: .regular)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()

        bind(to: clipsIntegrityValidatorStore)
    }
}

// MARK: - Bind

extension SceneRootSplitViewController {
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

extension SceneRootSplitViewController {
    private func configureViewHierarchy() {
        layoutProvider = SceneRootViewLayoutProvider(horizontalSizeClass: traitCollection.horizontalSizeClass,
                                                     intent: intent,
                                                     factory: factory)

        let sideBarItem = layoutProvider.layout
            .map { $0.sideBarItem }
            .eraseToAnyPublisher()
        sideBarController = SceneRootSideBarController(sideBarItem: sideBarItem)
        setViewController(sideBarController, for: .primary)
        sideBarController.delegate = self

        setViewController(compactBaseViewController, for: .compact)
        setViewController(secondaryBaseViewController, for: .secondary)

        delegate = self

        layoutProvider.layout
            .sink { [weak self] layout in self?.apply(layout: layout) }
            .store(in: &subscriptions)
    }

    private func apply(layout: SceneRootViewLayout) {
        switch layout {
        case let .compact(viewHierarchy):
            secondaryBaseViewController.children.forEach {
                ($0 as? UINavigationController)?.setViewControllers([], animated: false)
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }

            let tabBarController = viewHierarchy.tabBarController
            compactBaseViewController.addChild(tabBarController)
            compactBaseViewController.view.addSubview(tabBarController.view)
            tabBarController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(tabBarController.view.constraints(fittingIn: compactBaseViewController.view))

            // HACK: 画面によってはviewWillLayoutSubviewsにてデータを遅延ロードしている
            //       レイアウト切り替え後の最前面のViewはこのロードを強制的に実施させる
            //       たとえば、PreviewのDismiss時のアニメーションの際など、最前面のViewにデータが読み込まれていないと
            //       上手く画面遷移アニメーションが働かないケースがあるためのworkaround
            tabBarController.selectedViewController?.view.layoutIfNeeded()

        case let .split(viewHierarchy):
            compactBaseViewController.children.forEach {
                ($0 as? UITabBarController)?.setViewControllers([], animated: false)
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }
            secondaryBaseViewController.children.forEach {
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }

            let detailViewController = viewHierarchy.currentDetailViewController()
            secondaryBaseViewController.addChild(detailViewController)
            secondaryBaseViewController.view.addSubview(detailViewController.view)
            detailViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(detailViewController.view.constraints(fittingIn: secondaryBaseViewController.view))

            // HACK: 画面によってはviewWillLayoutSubviewsにてデータを遅延ロードしている
            //       レイアウト切り替え後の最前面のViewはこのロードを強制的に実施させる
            //       たとえば、PreviewのDismiss時のアニメーションの際など、最前面のViewにデータが読み込まれていないと
            //       上手く画面遷移アニメーションが働かないケースがあるためのworkaround
            detailViewController.view.layoutIfNeeded()
        }
    }
}

extension SceneRootSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        layoutProvider.apply(horizontalSizeClass: .compact)
        return .compact
    }
}

extension SceneRootSplitViewController: SceneRootSideBarControllerDelegate {
    // MARK: - SceneRootSideBarControllerDelegate

    func appRootSideBarController(_ controller: SceneRootSideBarController, didSelect item: SceneRoot.SideBarItem) {
        layoutProvider.select(item)
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

    func select(_ barItem: SceneRoot.BarItem) {
        layoutProvider.select(barItem)
    }
}
