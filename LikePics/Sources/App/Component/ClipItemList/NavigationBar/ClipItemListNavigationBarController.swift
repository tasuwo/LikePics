//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import LikePicsUIKit
import UIKit

class ClipItemListNavigationBarController {
    typealias Store = AnyStoring<ClipItemListNavigationBarState, ClipItemListNavigationBarAction, ClipItemListNavigationBarDependency>

    // MARK: - Properties

    // MARK: View

    weak var navigationItem: UINavigationItem?

    // MARK: BarButtons

    private let cancelButton = RoundedButton()
    private let selectButton = RoundedButton()
    private let resumeButton = RoundedButton()

    // MARK: Store

    let store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(store: Store) {
        self.store = store

        configureBarButtons()
    }

    // MARK: - View Life-Cycle Methods

    func viewDidLoad() {
        bind(to: store)
        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipItemListNavigationBarController {
    private func bind(to store: Store) {
        store.state
            .bind(\.leftItems) { [weak self] items in
                guard let leftItems = self?.resolveBarButtonItems(for: items) else { return }
                self?.navigationItem?.setLeftBarButtonItems(leftItems, animated: false)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.rightItems) { [weak self] items in
                guard let rightItems = self?.resolveBarButtonItems(for: items) else { return }
                self?.navigationItem?.setRightBarButtonItems(rightItems, animated: false)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - NavigationBar Items Builder

extension ClipItemListNavigationBarController {
    private func configureBarButtons() {
        cancelButton.title = L10n.confirmAlertCancel
        cancelButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapCancel)
        }), for: .touchUpInside)

        selectButton.title = L10n.barItemForSelectTitle
        selectButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapSelect)
        }), for: .touchUpInside)

        resumeButton.title = L10n.barItemForResume
        resumeButton.addAction(.init(handler: { [weak self] _ in
            self?.store.execute(.didTapResume)
        }), for: .touchUpInside)
    }
}

extension ClipItemListNavigationBarController {
    private func resolveBarButtonItems(for items: [ClipItemListNavigationBarState.Item]) -> [UIBarButtonItem] {
        return items.map { resolveBarButtonItem(for: $0) }
    }

    private func resolveBarButtonItem(for item: ClipItemListNavigationBarState.Item) -> UIBarButtonItem {
        let customView: UIView = {
            switch item.kind {
            case .cancel:
                return self.cancelButton

            case .select:
                return self.selectButton

            case .resume:
                return self.resumeButton
            }
        }()
        let barButtonItem = UIBarButtonItem(customView: customView)
        barButtonItem.isEnabled = item.isEnabled
        return barButtonItem
    }
}
