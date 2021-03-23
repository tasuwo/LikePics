//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class ClipPreviewPageBarController {
    typealias Store = LikePics.Store<ClipPreviewPageBarState, ClipPreviewPageBarAction, ClipPreviewPageBarDependency>

    // MARK: - Properties

    // MARK: View

    weak var barHostingViewController: UIViewController?
    weak var alertHostingViewController: UIViewController?

    // MARK: Item

    private var flexibleItem: UIBarButtonItem!
    private var browseItem: UIBarButtonItem!
    private var addItem: UIBarButtonItem!
    private var shareItem: UIBarButtonItem!
    private var deleteItem: UIBarButtonItem!
    private var infoItem: UIBarButtonItem!
    private var backItem: UIBarButtonItem!

    // MARK: Store

    let store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipPreviewPageBarState,
         dependency: ClipPreviewPageBarDependency)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipPreviewPageBarReducer.self)
    }

    // MARK: - View Life-Cycle Methods

    func traitCollectionDidChange(to traitCollection: UITraitCollection) {
        store.execute(.sizeClassChanged(traitCollection.verticalSizeClass))
    }

    func viewDidLoad() {
        configureBarButtons()

        bind(to: store)
    }
}

// MARK: - Bind

extension ClipPreviewPageBarController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            // HACK: navigationController は ViewController が Hierarchy に乗らないと nil となってしまう
            //       これを一瞬まつ
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                DispatchQueue.main.async {
                    self.barHostingViewController?.navigationController?.setToolbarHidden(state.isToolBarHidden, animated: true)
                }
            }

            let toolBarItems = self.resolveBarButtonItems(for: state.toolBarItems)
            self.barHostingViewController?.setToolbarItems(toolBarItems, animated: true)

            let leftBarButtonItems = self.resolveBarButtonItems(for: state.leftBarButtonItems)
            self.barHostingViewController?.navigationItem.setLeftBarButtonItems(leftBarButtonItems, animated: true)

            let rightBarButtonItems = self.resolveBarButtonItems(for: state.rightBarButtonItems)
            self.barHostingViewController?.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)

            self.presentAlertIfNeeded(for: state)
        }
        .store(in: &subscriptions)
    }

    private func presentAlertIfNeeded(for state: ClipPreviewPageBarState) {
        switch state.alert {
        case .addition:
            presentAddAlert()

        case let .deletion(includesRemoveFromClip: includesRemoveFromClip):
            presentDeleteAlert(includesRemoveFromClip: includesRemoveFromClip)

        case let .share(items: items):
            presentShareAlert(items: items)

        case .shareTargetSelection:
            presentShareTargetSelectionAlert(targetCount: state.parentState.items.count)

        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentDeleteAlert(includesRemoveFromClip: Bool) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipPreviewViewAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        if includesRemoveFromClip {
            alert.addAction(.init(title: L10n.clipPreviewViewAlertForDeleteClipItemAction, style: .destructive) { [weak self] _ in
                self?.store.execute(.alertDeleteClipItemConfirmed)
            })
        }
        alert.addAction(.init(title: L10n.clipPreviewViewAlertForDeleteClipAction, style: .destructive) { [weak self] _ in
            self?.store.execute(.alertDeleteClipConfirmed)
        })
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))

        alert.popoverPresentationController?.barButtonItem = deleteItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentAddAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipPreviewViewAlertForAddToAlbum, style: .default) { [weak self] _ in
            self?.store.execute(.alertAlbumAdditionConfirmed)
        })
        alert.addAction(.init(title: L10n.clipPreviewViewAlertForAddTag, style: .default) { [weak self] _ in
            self?.store.execute(.alertTagAdditionConfirmed)
        })
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))
        alert.popoverPresentationController?.barButtonItem = addItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentShareTargetSelectionAlert(targetCount: Int) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForShareItemsAction(targetCount)
        alert.addAction(.init(title: title, style: .destructive) { [weak self] _ in
            self?.store.execute(.alertShareClipConfirmed)
        })
        alert.addAction(.init(title: L10n.clipsListAlertForShareItemAction, style: .destructive) { [weak self] _ in
            self?.store.execute(.alertShareItemConfirmed)
        })
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))

        alert.popoverPresentationController?.barButtonItem = shareItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentShareAlert(items: [ClipItemImageShareItem]) {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = shareItem
        controller.completionWithItemsHandler = { [weak self] activity, success, _, _ in
            if success {
                self?.store.execute(.alertShareDismissed(true))
            } else {
                if activity == nil {
                    self?.store.execute(.alertShareDismissed(false))
                } else {
                    // NOP
                }
            }
        }

        alertHostingViewController?.present(controller, animated: true, completion: nil)
    }
}

// MARK: - Bar Items Builder

extension ClipPreviewPageBarController {
    private func configureBarButtons() {
        flexibleItem = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        browseItem = UIBarButtonItem(
            image: UIImage(systemName: "globe"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.browseButtonTapped)
            }),
            menu: nil
        )
        addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.addButtonTapped)
            }),
            menu: nil
        )
        shareItem = UIBarButtonItem(
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
        infoItem = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.infoButtonTapped)
            }),
            menu: nil
        )
        backItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left",
                           withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.backButtonTapped)
            }),
            menu: nil
        )
    }
}

extension ClipPreviewPageBarController {
    private func resolveBarButtonItems(for items: [ClipPreviewPageBarState.Item]) -> [UIBarButtonItem] {
        return items.reduce(into: [UIBarButtonItem]()) { array, item in
            if !array.isEmpty { array.append(flexibleItem) }
            array.append(resolveBarButtonItem(for: item))
        }
    }

    private func resolveBarButtonItem(for item: ClipPreviewPageBarState.Item) -> UIBarButtonItem {
        let buttonItem: UIBarButtonItem = {
            switch item.kind {
            case .back:
                return backItem

            case .browse:
                return browseItem

            case .add:
                return addItem

            case .share:
                return shareItem

            case .delete:
                return deleteItem

            case .info:
                return infoItem
            }
        }()
        buttonItem.isEnabled = item.isEnabled
        return buttonItem
    }
}
