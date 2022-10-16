//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CompositeKit
import Domain
import LikePicsUIKit
import UIKit

public class SceneRootTabBarController: UITabBarController {
    public typealias Factory = ViewControllerFactory
    typealias Store = CompositeKit.Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency>

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: View

    private var _loadingView: UIView?
    private var _loadingLabel: UILabel?

    // MARK: Store

    private var subscriptions = Set<AnyCancellable>()

    // MARK: Privates

    private let intent: Intent?

    // MARK: - Initializers

    public init(factory: Factory, intent: Intent?) {
        self.factory = factory
        self.intent = intent
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureTabBar()
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

    public var currentViewController: UIViewController? { selectedViewController }

    public func select(_ barItem: SceneRoot.BarItem) {
        selectedIndex = barItem.tabBarItem.rawValue
    }
}
