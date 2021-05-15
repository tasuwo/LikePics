//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class ClipCollectionToolBarController {
    typealias Store = LikePics.Store<ClipCollectionToolBarState, ClipCollectionToolBarAction, ClipCollectionToolBarDependency>

    // MARK: - Properties

    // MARK: View

    weak var toolBarHostingViewController: UIViewController?
    weak var alertHostingViewController: UIViewController?

    // MARK: Item

    private var flexibleItem: UIBarButtonItem!
    private var addItem: UIBarButtonItem!
    private var changeVisibilityItem: UIBarButtonItem!
    private var shareItem: UIBarButtonItem!
    private var deleteItem: UIBarButtonItem!
    private var mergeItem: UIBarButtonItem!

    // MARK: Store

    let store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipCollectionToolBarState,
         dependency: ClipCollectionToolBarDependency)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: ClipCollectionToolBarReducer())

        configureBarButtons()
    }

    // MARK: - View Life-Cycle Methods

    func viewDidLoad() {
        bind(to: store)
        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipCollectionToolBarController {
    private func bind(to store: Store) {
        store.state
            .bind(\.isHidden) { [weak self] isHidden in
                self?.toolBarHostingViewController?.navigationController?.setToolbarHidden(isHidden, animated: true)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.items) { [weak self] items in
                guard let items = self?.resolveBarButtonItems(for: items) else { return }
                self?.toolBarHostingViewController?.setToolbarItems(items, animated: true)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in
                guard let alert = alert else { return }
                self?.presentAlertIfNeeded(for: alert)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Alert Presentation

extension ClipCollectionToolBarController {
    private func presentAlertIfNeeded(for alert: ClipCollectionToolBarState.Alert) {
        switch alert {
        case .addition:
            presentAlertForAddition()

        case let .changeVisibility(targetCount: targetCount):
            presentAlertForChangeVisibility(targetCount: targetCount)

        case .deletion(includesRemoveFromAlbum: false, targetCount: let targetCount):
            presentAlertForDelete(targetCount: targetCount)

        case .deletion(includesRemoveFromAlbum: true, targetCount: _):
            presentAlertForDeleteIncludesRemoveFromAlbum()

        case let .share(items: items, targetCount: _):
            presentAlertForShare(items: items)
        }
    }

    private func presentAlertForAddition() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForAddToAlbum, style: .default) { [weak self] _ in
            self?.store.execute(.alertAddToAlbumConfirmed)
        })

        alert.addAction(.init(title: L10n.clipsListAlertForAddTag, style: .default) { [weak self] _ in
            self?.store.execute(.alertAddTagsConfirmed)
        })

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })

        alert.popoverPresentationController?.barButtonItem = addItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentAlertForChangeVisibility(targetCount: Int) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForChangeVisibilityMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForChangeVisibilityHideAction(targetCount), style: .destructive) { [weak self] _ in
            self?.store.execute(.alertHideConfirmed)
        })
        alert.addAction(.init(title: L10n.clipsListAlertForChangeVisibilityRevealAction(targetCount), style: .destructive) { [weak self] _ in
            self?.store.execute(.alertRevealConfirmed)
        })
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })

        alert.popoverPresentationController?.barButtonItem = changeVisibilityItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentAlertForDelete(targetCount: Int) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForDeleteAction(targetCount)
        alert.addAction(.init(title: title, style: .destructive) { [weak self] _ in
            self?.store.execute(.alertDeleteConfirmed)
        })
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })

        alert.popoverPresentationController?.barButtonItem = deleteItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentAlertForDeleteIncludesRemoveFromAlbum() {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForDeleteInAlbumMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForDeleteInAlbumActionRemoveFromAlbum, style: .destructive) { [weak self] _ in
            self?.store.execute(.alertRemoveFromAlbumConfirmed)
        })
        alert.addAction(.init(title: L10n.clipsListAlertForDeleteInAlbumActionDelete, style: .destructive) { [weak self] _ in
            self?.store.execute(.alertDeleteConfirmed)
        })
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })

        alert.popoverPresentationController?.barButtonItem = deleteItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentAlertForShare(items: [ClipItemImageShareItem]) {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = shareItem
        controller.completionWithItemsHandler = { [weak self] activity, success, _, _ in
            if success {
                self?.store.execute(.alertShareConfirmed(true))
            } else {
                if activity == nil {
                    self?.store.execute(.alertShareConfirmed(false))
                } else {
                    // NOP
                }
            }
        }

        alertHostingViewController?.present(controller, animated: true, completion: nil)
    }
}

// MARK: - ToolBar Items Builder

extension ClipCollectionToolBarController {
    private func configureBarButtons() {
        flexibleItem = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.addButtonTapped)
            }),
            menu: nil
        )
        changeVisibilityItem = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "eye"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.changeVisibilityButtonTapped)
            }),
            menu: nil
        )
        shareItem = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.shareButtonTapped)
            }),
            menu: nil
        )
        deleteItem = UIBarButtonItem(
            systemItem: .trash,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.deleteButtonTapped)
            }),
            menu: nil
        )
        mergeItem = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "rectangle.and.paperclip"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.mergeButtonTapped)
            }),
            menu: nil
        )
    }
}

extension ClipCollectionToolBarController {
    private func resolveBarButtonItems(for items: [ClipCollectionToolBarState.Item]) -> [UIBarButtonItem] {
        return items.reduce(into: [UIBarButtonItem]()) { array, item in
            if !array.isEmpty { array.append(flexibleItem) }
            array.append(resolveBarButtonItem(for: item))
        }
    }

    private func resolveBarButtonItem(for item: ClipCollectionToolBarState.Item) -> UIBarButtonItem {
        let buttonItem: UIBarButtonItem = {
            switch item.kind {
            case .add:
                return addItem

            case .changeVisibility:
                return changeVisibilityItem

            case .share:
                return shareItem

            case .delete:
                return deleteItem

            case .merge:
                return mergeItem
            }
        }()
        buttonItem.isEnabled = item.isEnabled
        return buttonItem
    }
}
