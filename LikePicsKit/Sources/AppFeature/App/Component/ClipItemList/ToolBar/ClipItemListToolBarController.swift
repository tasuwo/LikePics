//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import UIKit

class ClipItemListToolBarController {
    typealias Store = AnyStoring<ClipItemListToolBarState, ClipItemListToolBarAction, ClipItemListToolBarDependency>

    // MARK: - Properties

    // MARK: View

    weak var toolBar: UIToolbar?
    weak var alertHostingViewController: UIViewController?

    // MARK: Component

    private let siteUrlEditAlert: TextEditAlertController

    // MARK: Item

    private var flexibleItem: UIBarButtonItem!
    private var editUrlItem: UIBarButtonItem!
    private var shareItem: UIBarButtonItem!
    private var deleteItem: UIBarButtonItem!

    // MARK: Store

    let store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: Service

    private let imageQueryService: ImageQueryServiceProtocol

    // MARK: - Initializers

    init(
        store: Store,
        siteUrlEditAlertState: TextEditAlertState,
        imageQueryService: ImageQueryServiceProtocol
    ) {
        self.store = store
        self.siteUrlEditAlert = .init(state: siteUrlEditAlertState)
        self.imageQueryService = imageQueryService

        configureBarButtons()

        siteUrlEditAlert.textEditAlertDelegate = self
    }

    // MARK: - View Life-Cycle Methods

    func viewDidLoad() {
        bind(to: store)
        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipItemListToolBarController {
    private func bind(to store: Store) {
        store.state
            .bind(\.items) { [weak self] items in
                guard let items = self?.resolveBarButtonItems(for: items) else { return }
                self?.toolBar?.items = items
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in
                guard let alert = alert else { return }
                MainActor.assumeIsolated {
                    self?.presentAlertIfNeeded(for: alert)
                }
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Alert Presentation

extension ClipItemListToolBarController {
    @MainActor
    private func presentAlertIfNeeded(for alert: ClipItemListToolBarState.Alert) {
        switch alert {
        case let .deletion(targetCount: targetCount):
            presentAlertForDelete(targetCount: targetCount)

        case let .share(imageIds: imageIds, targetCount: _):
            presentAlertForShare(imageIds: imageIds)

        case .editUrl:
            guard let viewController = alertHostingViewController else {
                store.execute(.alertDismissed)
                return
            }
            siteUrlEditAlert.present(
                with: "",
                validator: { text in
                    guard let text = text else { return false }
                    return text.isEmpty == false
                        && URL(string: text) != nil
                },
                on: viewController
            )
        }
    }

    private func presentAlertForDelete(targetCount: Int) {
        let alert = UIAlertController(
            title: nil,
            message: L10n.alertForDeleteClipItemsMessage,
            preferredStyle: .actionSheet
        )

        let title = L10n.alertForDeleteClipItemsAction(targetCount)
        alert.addAction(
            .init(title: title, style: .destructive) { [weak self] _ in
                self?.store.execute(.alertDeleteConfirmed)
            }
        )
        alert.addAction(
            .init(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
                self?.store.execute(.alertDismissed)
            }
        )

        alert.popoverPresentationController?.barButtonItem = deleteItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentAlertForShare(imageIds: [ImageContainer.Identity]) {
        let items = imageIds.map { ClipItemImageShareItem(imageId: $0, imageQueryService: imageQueryService) }
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

extension ClipItemListToolBarController {
    private func configureBarButtons() {
        flexibleItem = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        editUrlItem = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.editUrlButtonTapped)
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
    }
}

extension ClipItemListToolBarController {
    private func resolveBarButtonItems(for items: [ClipItemListToolBarState.Item]) -> [UIBarButtonItem] {
        return items.reduce(into: [UIBarButtonItem]()) { array, item in
            if !array.isEmpty { array.append(flexibleItem) }
            array.append(resolveBarButtonItem(for: item))
        }
    }

    private func resolveBarButtonItem(for item: ClipItemListToolBarState.Item) -> UIBarButtonItem {
        let buttonItem: UIBarButtonItem = {
            switch item.kind {
            case .share:
                return shareItem

            case .delete:
                return deleteItem

            case .editUrl:
                return editUrlItem
            }
        }()
        buttonItem.isEnabled = item.isEnabled
        return buttonItem
    }
}

extension ClipItemListToolBarController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        guard let url = URL(string: text) else {
            store.execute(.alertDismissed)
            return
        }
        store.execute(.alertSiteUrlEditted(url))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}
