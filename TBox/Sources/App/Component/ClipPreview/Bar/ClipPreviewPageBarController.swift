//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
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

    // MARK: Privates

    private let imageQueryService: ImageQueryServiceProtocol

    // MARK: - Initializers

    init(state: ClipPreviewPageBarState,
         dependency: ClipPreviewPageBarDependency)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipPreviewPageBarReducer())
        self.imageQueryService = dependency.imageQueryService
    }

    // MARK: - View Life-Cycle Methods

    func traitCollectionDidChange(to traitCollection: UITraitCollection) {
        store.execute(.sizeClassChanged(isVerticalSizeClassCompact: traitCollection.verticalSizeClass == .compact))
    }

    func viewDidAppear() {
        // HACK: 画面遷移時に背景色が消失してしまうケースがあるので、再度適用を行う
        updateBackground(isFullscreen: store.stateValue.isFullscreen)
    }

    func viewDidLoad() {
        configureBarButtons()

        bind(to: store)
    }
}

// MARK: - Bind

extension ClipPreviewPageBarController {
    private func bind(to store: Store) {
        store.state
            // Note: 画面遷移アニメーション時に背景色がつくことを避けるため、delayさせない
            .bind(\.isFullscreen) { [weak self] isFullscreen in self?.updateBackground(isFullscreen: isFullscreen) }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: { $0.isToolBarHidden == $1.isToolBarHidden && $0.isNavigationBarHidden == $1.isNavigationBarHidden })
            // HACK: navigationController は ViewController が Hierarchy に乗らないと nil となってしまうこれを一瞬まつ
            .delay(for: 0.01, scheduler: RunLoop.main)
            .sink { [weak self] state in self?.updateBarAppearance(state: state) }
            .store(in: &subscriptions)

        store.state
            .bind(\.toolBarItems) { [weak self] items in
                guard let self = self else { return }
                let toolBarItems = self.resolveBarButtonItems(for: items)
                self.barHostingViewController?.setToolbarItems(toolBarItems, animated: true)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.leftBarButtonItems) { [weak self] items in
                guard let self = self else { return }
                let leftBarButtonItems = self.resolveBarButtonItems(for: items)
                self.barHostingViewController?.navigationItem.setLeftBarButtonItems(leftBarButtonItems, animated: true)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.rightBarButtonItems) { [weak self] items in
                guard let self = self else { return }
                let rightBarButtonItems = self.resolveBarButtonItems(for: items)
                self.barHostingViewController?.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: true)
            }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.alert)
            .sink { [weak self] state in self?.presentAlertIfNeeded(for: state) }
            .store(in: &subscriptions)
    }

    private func updateBackground(isFullscreen: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.barHostingViewController?.parent?.view.backgroundColor = isFullscreen ? .black : Asset.Color.backgroundClient.color
        }
    }

    private func updateBarAppearance(state: ClipPreviewPageBarState) {
        barHostingViewController?.setNeedsStatusBarAppearanceUpdate()

        guard let baseView = barHostingViewController?.navigationController?.view else { return }
        UIView.transition(with: baseView, duration: 0.2, options: .transitionCrossDissolve) {
            self.barHostingViewController?.navigationController?.toolbar.isHidden = state.isToolBarHidden
            self.barHostingViewController?.navigationController?.navigationBar.isHidden = state.isNavigationBarHidden
        }
    }

    private func presentAlertIfNeeded(for state: ClipPreviewPageBarState) {
        switch state.alert {
        case .addition:
            presentAddAlert()

        case let .deletion(includesRemoveFromClip: includesRemoveFromClip):
            presentDeleteAlert(includesRemoveFromClip: includesRemoveFromClip)

        case let .share(imageIds: imageIds):
            presentShareAlert(imageIds: imageIds)

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

    private func presentShareAlert(imageIds: [ImageContainer.Identity]) {
        let items = imageIds.map { ClipItemImageShareItem(imageId: $0, imageQueryService: imageQueryService) }
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
        flexibleItem.accessibilityIdentifier = "\(String(describing: Self.self)).flexibleItem"
        browseItem = UIBarButtonItem(
            image: UIImage(systemName: "globe"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.browseButtonTapped)
            }),
            menu: nil
        )
        browseItem.accessibilityIdentifier = "\(String(describing: Self.self)).browseItem"
        addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.addButtonTapped)
            }),
            menu: nil
        )
        addItem.accessibilityIdentifier = "\(String(describing: Self.self)).addItem"
        shareItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.shareButtonTapped)
            }),
            menu: nil
        )
        shareItem.accessibilityIdentifier = "\(String(describing: Self.self)).shareItem"
        deleteItem = UIBarButtonItem(
            systemItem: .trash,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.deleteButtonTapped)
            }),
            menu: nil
        )
        deleteItem.accessibilityIdentifier = "\(String(describing: Self.self)).deleteItem"
        infoItem = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.infoButtonTapped)
            }),
            menu: nil
        )
        infoItem.accessibilityIdentifier = "\(String(describing: Self.self)).infoItem"
        backItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left",
                           withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.backButtonTapped)
            }),
            menu: nil
        )
        backItem.accessibilityIdentifier = "\(String(describing: Self.self)).backItem"
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
