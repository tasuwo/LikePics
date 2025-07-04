//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CompositeKit
import Domain
import LikePicsUIKit
import UIKit

class ClipPreviewPageBarController {
    typealias Store = AnyStoring<ClipPreviewPageBarState, ClipPreviewPageBarAction, ClipPreviewPageBarDependency>

    // MARK: - Properties

    // MARK: View

    weak var barHostingViewController: UIViewController?
    weak var alertHostingViewController: UIViewController?

    private var pageLabelContainer: UIView!
    private var pageLabel: UILabel!

    // MARK: Item

    private var flexibleItem: UIBarButtonItem!
    private var playItem: UIBarButtonItem!
    private var pauseItem: UIBarButtonItem!
    private var addItem: UIBarButtonItem!
    private var shareItem: UIBarButtonItem!
    private var deleteItem: UIBarButtonItem!
    private var optionItem: UIBarButtonItem!
    private var listItem: UIBarButtonItem!
    private var backItem: UIBarButtonItem!

    // MARK: Store

    let store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: Privates

    private let imageQueryService: ImageQueryServiceProtocol

    // MARK: - Initializers

    init(
        store: Store,
        imageQueryService: ImageQueryServiceProtocol
    ) {
        self.store = store
        self.imageQueryService = imageQueryService
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
        configurePageCounter()

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
            .removeDuplicates(by: {
                $0.isToolBarHidden == $1.isToolBarHidden
                    && $0.isNavigationBarHidden == $1.isNavigationBarHidden
                    && $0.isPageCounterHidden == $1.isPageCounterHidden
            })
            // HACK: navigationController は ViewController が Hierarchy に乗らないと nil となってしまうこれを一瞬まつ
            .delay(for: 0.01, scheduler: RunLoop.main)
            .sink { [weak self] state in self?.updateBarAppearance(state: state) }
            .store(in: &subscriptions)

        store.state
            .bind(\.toolBarItems) { [weak self] items in
                guard let self = self else { return }
                let toolBarItems = self.resolveBarButtonItems(for: items)
                self.barHostingViewController?.setToolbarItems(toolBarItems, animated: false)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.leftBarButtonItems) { [weak self] items in
                guard let self = self else { return }
                let leftBarButtonItems = self.resolveBarButtonItems(for: items)
                self.barHostingViewController?.navigationItem.setLeftBarButtonItems(leftBarButtonItems, animated: false)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.rightBarButtonItems) { [weak self] items in
                guard let self = self else { return }
                let rightBarButtonItems = self.resolveBarButtonItems(for: items)
                self.barHostingViewController?.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: false)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.optionMenuItems) { [weak self] items in
                guard let self = self else { return }
                let menu = self.resolveOptionMenu(for: items)
                self.optionItem.menu = menu
                self.optionItem.isEnabled = !menu.children.isEmpty
            }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.alert)
            .sink { [weak self] state in self?.presentAlertIfNeeded(for: state) }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                guard state.clipItems.count > 1 else {
                    self.pageLabelContainer.isHidden = true
                    self.pageLabel.text = nil
                    return
                }
                if let pageCount = state.pageCount {
                    self.pageLabelContainer.isHidden = false
                    self.pageLabel.text = pageCount
                } else {
                    self.pageLabelContainer.isHidden = true
                    self.pageLabel.text = nil
                }
            }
            .store(in: &subscriptions)
    }

    // MARK: Appearance

    private func updateBackground(isFullscreen: Bool) {
        UIView.likepics_animate(withDuration: 0.2) {
            self.barHostingViewController?.parent?.view.backgroundColor = isFullscreen ? .black : Asset.Color.background.color
        }
    }

    private func updateBarAppearance(state: ClipPreviewPageBarState) {
        barHostingViewController?.setNeedsStatusBarAppearanceUpdate()

        guard let baseView = barHostingViewController?.navigationController?.view else { return }
        UIView.transition(with: baseView, duration: 0.2, options: .transitionCrossDissolve) {
            self.barHostingViewController?.navigationController?.toolbar.isHidden = state.isToolBarHidden
            self.barHostingViewController?.navigationController?.navigationBar.isHidden = state.isNavigationBarHidden
            self.pageLabelContainer.alpha = state.isPageCounterHidden ? 0 : 1
        }
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for state: ClipPreviewPageBarState) {
        switch state.alert {
        case .addition:
            presentAddAlert()

        case let .deletion(includesRemoveFromClip: includesRemoveFromClip):
            presentDeleteAlert(includesRemoveFromClip: includesRemoveFromClip)

        case let .share(imageIds: imageIds):
            presentShareAlert(imageIds: imageIds)

        case .shareTargetSelection:
            presentShareTargetSelectionAlert(targetCount: state.clipItems.count)

        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(
            .init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
                self?.store.execute(.alertDismissed)
            }
        )
        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentDeleteAlert(includesRemoveFromClip: Bool) {
        let alert = UIAlertController(
            title: nil,
            message: L10n.clipPreviewViewAlertForDeleteMessage,
            preferredStyle: .actionSheet
        )

        if includesRemoveFromClip {
            alert.addAction(
                .init(title: L10n.clipPreviewViewAlertForDeleteClipItemAction, style: .destructive) { [weak self] _ in
                    self?.store.execute(.alertDeleteClipItemConfirmed)
                }
            )
        }
        alert.addAction(
            .init(title: L10n.clipPreviewViewAlertForDeleteClipAction, style: .destructive) { [weak self] _ in
                self?.store.execute(.alertDeleteClipConfirmed)
            }
        )
        alert.addAction(
            .init(
                title: L10n.confirmAlertCancel,
                style: .cancel,
                handler: { [weak self] _ in
                    self?.store.execute(.alertDismissed)
                }
            )
        )

        alert.popoverPresentationController?.barButtonItem = deleteItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentAddAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(
            .init(title: L10n.clipPreviewViewAlertForAddToAlbum, style: .default) { [weak self] _ in
                self?.store.execute(.alertAlbumAdditionConfirmed)
            }
        )
        alert.addAction(
            .init(title: L10n.clipPreviewViewAlertForAddTag, style: .default) { [weak self] _ in
                self?.store.execute(.alertTagAdditionConfirmed)
            }
        )
        alert.addAction(
            .init(
                title: L10n.confirmAlertCancel,
                style: .cancel,
                handler: { [weak self] _ in
                    self?.store.execute(.alertDismissed)
                }
            )
        )
        alert.popoverPresentationController?.barButtonItem = addItem

        alertHostingViewController?.present(alert, animated: true, completion: nil)
    }

    private func presentShareTargetSelectionAlert(targetCount: Int) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForShareItemsAction(targetCount)
        alert.addAction(
            .init(title: title, style: .destructive) { [weak self] _ in
                self?.store.execute(.alertShareClipConfirmed)
            }
        )
        alert.addAction(
            .init(title: L10n.clipsListAlertForShareItemAction, style: .destructive) { [weak self] _ in
                self?.store.execute(.alertShareItemConfirmed)
            }
        )
        alert.addAction(
            .init(
                title: L10n.confirmAlertCancel,
                style: .cancel,
                handler: { [weak self] _ in
                    self?.store.execute(.alertDismissed)
                }
            )
        )

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

        playItem = UIBarButtonItem(
            image: UIImage(systemName: "play.fill"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.playButtonTapped)
            }),
            menu: nil
        )
        playItem.accessibilityIdentifier = "\(String(describing: Self.self)).playItem"

        pauseItem = UIBarButtonItem(
            image: UIImage(systemName: "pause.fill"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.pauseButtonTapped)
            }),
            menu: nil
        )
        pauseItem.accessibilityIdentifier = "\(String(describing: Self.self)).pauseItem"

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

        optionItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: nil
        )
        optionItem.accessibilityIdentifier = "\(String(describing: Self.self)).ellipsis"

        listItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.listButtonTapped)
            }),
            menu: nil
        )
        listItem.accessibilityIdentifier = "\(String(describing: Self.self)).listItem"

        backItem = UIBarButtonItem(
            image: UIImage(
                systemName: "chevron.left",
                withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
            ),
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.backButtonTapped)
            }),
            menu: nil
        )
        backItem.accessibilityIdentifier = "\(String(describing: Self.self)).backItem"
    }

    private func configurePageCounter() {
        guard let view = barHostingViewController?.view else { return }

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 5
        container.layer.cornerCurve = .continuous

        let label = UILabel()

        let metrics = UIFontMetrics(forTextStyle: .body)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        label.font = metrics.scaledFont(for: font)

        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])

        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])

        pageLabelContainer = container
        pageLabel = label
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

            case .list:
                return listItem

            case .play:
                return playItem

            case .pause:
                return pauseItem

            case .add:
                return addItem

            case .share:
                return shareItem

            case .delete:
                return deleteItem

            case .option:
                return optionItem
            }
        }()
        buttonItem.isEnabled = item.isEnabled
        return buttonItem
    }
}

extension ClipPreviewPageBarController {
    private func resolveOptionMenu(for items: [ClipPreviewPageBarState.OptionMenuItem]) -> UIMenu {
        let children: [UIAction] = items.map { item in
            switch item {
            case .info:
                return UIAction(title: L10n.ClipPreview.OptionMenuItemTitle.info, image: UIImage(systemName: "info.circle")) { [weak self] _ in
                    self?.store.execute(.infoButtonTapped)
                }

            case .browse:
                return UIAction(title: L10n.ClipPreview.OptionMenuItemTitle.browse, image: UIImage(systemName: "globe")) { [weak self] _ in
                    self?.store.execute(.browseButtonTapped)
                }

            case .playConfig:
                return UIAction(title: L10n.ClipPreview.OptionMenuItemTitle.playConfig, image: UIImage(systemName: "gearshape")) { [weak self] _ in
                    self?.store.execute(.playConfigButtonTapped)
                }
            }
        }
        return UIMenu(title: "", children: children)
    }
}
