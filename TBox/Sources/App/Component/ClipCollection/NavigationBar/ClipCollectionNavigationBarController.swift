//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import TBoxUIKit
import UIKit

class ClipCollectionNavigationBarController {
    typealias Store = LikePics.Store<ClipCollectionNavigationBarState, ClipCollectionNavigationBarAction, ClipCollectionNavigationBarDependency>

    // MARK: - Properties

    // MARK: View

    weak var navigationItem: UINavigationItem?

    // MARK: BarButtons

    private let cancelButton = RoundedButton()
    private let selectAllButton = RoundedButton()
    private let deselectAllButton = RoundedButton()
    private let selectButton = RoundedButton()
    private let reorderButton = RoundedButton()
    private let doneButton = RoundedButton()

    // MARK: Store

    let store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipCollectionNavigationBarState,
         dependency: ClipCollectionNavigationBarDependency)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: ClipCollectionNavigationBarReducer.self)

        configureBarButtons()
    }

    // MARK: - View Life-Cycle Methods

    func viewDidLoad() {
        bind(to: store)
        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipCollectionNavigationBarController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            let leftItems = self.resolveBarButtonItems(for: state.leftItems)
            self.navigationItem?.leftBarButtonItems = leftItems

            let rightItems = self.resolveBarButtonItems(for: state.rightItems)
            self.navigationItem?.rightBarButtonItems = rightItems
        }
        .store(in: &subscriptions)
    }
}

// MARK: - NavigationBar Items Builder

extension ClipCollectionNavigationBarController {
    private func configureBarButtons() {
        cancelButton.title = L10n.confirmAlertCancel
        cancelButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapCancel)
        }), for: .touchUpInside)

        selectAllButton.title = L10n.clipsListRightBarItemForSelectAllTitle
        selectAllButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapSelectAll)
        }), for: .touchUpInside)

        deselectAllButton.title = L10n.clipsListRightBarItemForDeselectAllTitle
        deselectAllButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapDeselectAll)
        }), for: .touchUpInside)

        selectButton.title = L10n.clipsListRightBarItemForSelectTitle
        selectButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapSelect)
        }), for: .touchUpInside)

        reorderButton.title = L10n.clipsListRightBarItemForReorder
        reorderButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapReorder)
        }), for: .touchUpInside)

        doneButton.title = L10n.clipsListRightBarItemForDone
        doneButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapDone)
        }), for: .touchUpInside)
    }
}

extension ClipCollectionNavigationBarController {
    private func resolveBarButtonItems(for items: [ClipCollectionNavigationBarState.Item]) -> [UIBarButtonItem] {
        return items.map { resolveBarButtonItem(for: $0) }
    }

    private func resolveBarButtonItem(for item: ClipCollectionNavigationBarState.Item) -> UIBarButtonItem {
        let customView: UIView = {
            switch item.kind {
            case .cancel:
                return self.cancelButton

            case .selectAll:
                return self.selectAllButton

            case .deselectAll:
                return self.deselectAllButton

            case .select:
                return self.selectButton

            case .reorder:
                return self.reorderButton

            case .done:
                return self.doneButton
            }
        }()
        let barButtonItem = UIBarButtonItem(customView: customView)
        barButtonItem.isEnabled = item.isEnabled
        return barButtonItem
    }
}
