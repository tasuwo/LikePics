//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class ClipPreviewPageBarController: UIViewController {
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

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.store.execute(.sizeClassChanged(self.traitCollection.verticalSizeClass))
        }
    }
}

// MARK: - Bind

extension ClipPreviewPageBarController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            self.barHostingViewController?.navigationController?.setToolbarHidden(state.isToolBarHidden, animated: false)

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

        case let .share(data: data):
            presentShareAlert(data: data)

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
        self.present(alert, animated: true, completion: nil)
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
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = deleteItem

        present(alert, animated: true, completion: nil)
    }

    private func presentAddAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipPreviewViewAlertForAddToAlbum, style: .default) { [weak self] _ in
            self?.store.execute(.alertAlbumAdditionConfirmed)
        })
        alert.addAction(.init(title: L10n.clipPreviewViewAlertForAddTag, style: .default) { [weak self] _ in
            self?.store.execute(.alertTagAdditionConfirmed)
        })
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))
        alert.popoverPresentationController?.barButtonItem = addItem

        present(alert, animated: true, completion: nil)
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
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.barButtonItem = shareItem

        present(alert, animated: true, completion: nil)
    }

    private func presentShareAlert(data: [Data]) {
        let controller = UIActivityViewController(activityItems: data, applicationActivities: nil)
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

        present(controller, animated: true, completion: nil)
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
                self?.store.execute(.addButtonTapped)
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
