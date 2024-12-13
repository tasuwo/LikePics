//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class SceneRootViewLayoutProvider {
    // MARK: - Properties

    var layout: AnyPublisher<SceneRootViewLayout, Never> { _layout.eraseToAnyPublisher() }
    var currentTopViewController: UIViewController? { _layout.value.topViewController }

    private let factory: ViewControllerFactory
    private var _layout: CurrentValueSubject<SceneRootViewLayout, Never>

    // MARK: - Initializers

    init(horizontalSizeClass: UIUserInterfaceSizeClass,
         intent: Intent?,
         factory: ViewControllerFactory)
    {
        self.factory = factory
        _layout = .init(.init(horizontalSizeClass: horizontalSizeClass,
                              intent: intent,
                              factory: factory))
    }
}

// MARK: - Methods

extension SceneRootViewLayoutProvider {
    @MainActor
    func apply(horizontalSizeClass: UIUserInterfaceSizeClass) {
        guard let nextLayout = _layout.value.applying(horizontalSizeClass: horizontalSizeClass, factory: factory) else { return }
        _layout.send(nextLayout)
    }

    func select(_ sideBarItem: SceneRoot.SideBarItem) {
        guard case let .split(viewHierarchy) = _layout.value else { return }
        guard let nextViewHierarchy = viewHierarchy.selecting(sideBarItem) else { return }
        _layout.send(.split(nextViewHierarchy))
    }

    func select(_ barItem: SceneRoot.BarItem) {
        switch _layout.value {
        case let .compact(viewHierarchy):
            viewHierarchy.tabBarController.selectedIndex = barItem.tabBarItem.rawValue

        case let .split(viewHierarchy):
            guard let nextViewHierarchy = viewHierarchy.selecting(barItem.sideBarItem) else { return }
            _layout.send(.split(nextViewHierarchy))
        }
    }
}
