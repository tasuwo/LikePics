//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class ClipCollectionViewController: UIViewController, ClipCollectionAlertPresentable {
    typealias Layout = ClipCollectionViewLayout
    typealias ClipCollectionViewStore = Store<ClipCollectionState, ClipCollectionAction, ClipCollectionDependency>

    struct BarDependencyContainer: HasClipCollectionToolBarDelegate, HasClipCollectionNavigationBarDelegate {
        weak var clipCollectionToolBarDelegate: ClipCollectionToolBarDelegate?
        weak var clipCollectionNavigationBarDelegate: ClipCollectionNavigationBarDelegate?
    }

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private let emptyMessageView = EmptyMessageView()

    private let thumbnailLoader: ThumbnailLoaderProtocol

    // MARK: Component

    private var navigationBarController: ClipCollectionNavigationBarController!
    private var toolBarController: ClipCollectionToolBarController!

    // MARK: Builder

    private let menuBuilder: ClipCollectionMenuBuildable

    // MARK: Store

    private var store: ClipCollectionViewStore
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: Temporary

    private var _previousState: ClipCollectionState?

    // MARK: - Initializers

    init(state: ClipCollectionState,
         navigationBarState: ClipCollectionNavigationBarState,
         toolBarState: ClipCollectionToolBarState,
         dependency: ClipCollectionDependency,
         thumbnailLoader: ThumbnailLoaderProtocol,
         menuBuilder: ClipCollectionMenuBuildable)
    {
        self.store = ClipCollectionViewStore(initialState: state, dependency: dependency, reducer: ClipCollectionReducer.self)

        self.thumbnailLoader = thumbnailLoader
        self.menuBuilder = menuBuilder

        super.init(nibName: nil, bundle: nil)

        let barDependency = BarDependencyContainer(clipCollectionToolBarDelegate: self,
                                                   clipCollectionNavigationBarDelegate: self)
        navigationBarController = ClipCollectionNavigationBarController(state: navigationBarState, dependency: barDependency)
        toolBarController = ClipCollectionToolBarController(state: toolBarState, dependency: barDependency)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureEmptyMessageView()

        navigationBarController.navigationItem = navigationItem
        toolBarController.toolBarHostingViewController = self
        toolBarController.alertHostingViewController = self

        navigationBarController.viewDidLoad()
        toolBarController.viewDidLoad()

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

// MARK: - Bind

extension ClipCollectionViewController {
    private func bind(to store: ClipCollectionViewStore) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.global().async {
                var snapshot = Layout.Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(state.clips)
                self.dataSource.apply(snapshot, animatingDifferences: true) {
                    self.updateHiddenIconAppearance()
                }
            }

            self.collectionView.isHidden = !state.isCollectionViewDisplaying

            self.emptyMessageView.alpha = state.isEmptyMessageViewDisplaying ? 1 : 0

            self.isEditing = state.operation.isEditing
            self.collectionView.isEditing = state.operation.isEditing
            // TODO: 各Cell側で設定させる
            self.collectionView.visibleCells
                .compactMap { $0 as? ClipCollectionViewCell }
                .forEach { $0.visibleSelectedMark = state.operation.isEditing }

            self.applySelections(for: state)
            self.presentAlertIfNeeded(for: state.alert)

            // Propagation

            self.toolBarController.store.execute(.stateChanged(selectionCount: state.selections.count,
                                                               operation: state.operation))
            self.navigationBarController.store.execute(.stateChanged(clipCount: state.clips.count,
                                                                     selectionCount: state.selections.count,
                                                                     operation: state.operation))
        }
        .store(in: &subscriptions)
    }

    private func applySelections(for state: ClipCollectionState) {
        defer { _previousState = state }

        guard let previousState = _previousState else {
            // `_previousState` がnil == 初回表示時はCollectionViewの選択状態が空であることが前提なので、deselectは行わずselectのみ反映する
            state
                .selectedClips
                .compactMap { self.dataSource.indexPath(for: $0) }
                .forEach { self.collectionView.selectItem(at: $0, animated: false, scrollPosition: []) }
            return
        }

        // NOTE: パフォーマンスのために、選択状態は差分のみ更新する

        state.newSelectedClips(from: previousState)
            .compactMap { self.dataSource.indexPath(for: $0) }
            .forEach { self.collectionView.selectItem(at: $0, animated: false, scrollPosition: []) }

        state.newDeselectedClips(from: previousState)
            .compactMap { self.dataSource.indexPath(for: $0) }
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
    }

    private func presentAlertIfNeeded(for alert: ClipCollectionState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case let .deletion(clipId: _, at: indexPath):
            guard let cell = collectionView.cellForItem(at: indexPath) else { return }
            presentDeleteAlert(at: cell, in: collectionView) { [weak self] in
                self?.store.execute(.alertDeleteConfirmed)
            }

        case let .purge(clipId: _, at: indexPath):
            guard let cell = collectionView.cellForItem(at: indexPath) else { return }
            presentPurgeAlert(at: cell, in: collectionView) { [weak self] in
                self?.store.execute(.alertPurgeConfirmed)
            }

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

    private func updateHiddenIconAppearance() {
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let clip = dataSource.itemIdentifier(for: indexPath) else { return }
            guard let cell = collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell else { return }
            guard clip.isHidden != cell.isHiddenClip else { return }
            cell.setClipHiding(clip.isHidden, animated: true)
        }
    }
}

// MARK: - Configuration

extension ClipCollectionViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = ClipCollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout(with: self))
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelectionDuringEditing = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))

        emptyMessageView.alpha = 0
        view.addSubview(self.emptyMessageView)
        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        dataSource = Layout.configureDataSource(collectionView: collectionView, thumbnailLoader: thumbnailLoader)
    }

    private func configureEmptyMessageView() {
        emptyMessageView.title = L10n.topClipViewEmptyTitle
        emptyMessageView.message = L10n.topClipViewEmptyMessage
        emptyMessageView.isActionButtonHidden = true
    }
}

extension ClipCollectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell else { return false }
        return !cell.isLoading
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell else { return false }
        return !cell.isLoading
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clip = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(clip.id))
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let clip = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.deselected(clip.id))
    }
}

extension ClipCollectionViewController {
    // MARK: - UICollectionViewDelegate (Context Menu)

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let clip = dataSource.itemIdentifier(for: indexPath), !isEditing else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil,
                                          actionProvider: self.makeActionProvider(for: clip, at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return UITargetedPreview.create(for: configuration, collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return UITargetedPreview.create(for: configuration, collectionView: collectionView)
    }

    private func makeActionProvider(for clip: Clip, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        let context: ClipCollection.Context = .init(isAlbum: store.stateValue.context.isAlbum)
        let items = menuBuilder.build(for: clip, context: context).map {
            self.makeElement(from: $0, for: clip, at: indexPath)
        }
        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeElement(from element: ClipCollection.MenuElement, for clip: Clip, at indexPath: IndexPath) -> UIMenuElement {
        switch element {
        case let .item(item):
            return self.makeElement(from: item, for: clip, at: indexPath)

        case let .subMenu(subMenu):
            let title = Self.resolveTitle(for: subMenu.kind)
            let icon = Self.resolveIcon(for: subMenu.kind)
            let children = subMenu.children.map { self.makeElement(from: $0, for: clip, at: indexPath) }
            return UIMenu(title: title, image: icon, options: subMenu.isInline ? .displayInline : [], children: children)
        }
    }

    private static func resolveTitle(for kind: ClipCollection.SubMenu.Kind) -> String {
        switch kind {
        case .add:
            return L10n.clipsListContextMenuAdd

        case .others:
            return L10n.clipsListContextMenuOthers
        }
    }

    private static func resolveIcon(for kind: ClipCollection.SubMenu.Kind) -> UIImage? {
        switch kind {
        case .add:
            return UIImage(systemName: "plus")

        case .others:
            return UIImage(systemName: "ellipsis")
        }
    }

    private func makeElement(from item: ClipCollection.MenuItem, for clip: Clip, at indexPath: IndexPath) -> UIMenuElement {
        switch item {
        case .addTag:
            return UIAction(title: L10n.clipsListContextMenuAddTag,
                            image: UIImage(systemName: "tag.fill")) { [weak self] _ in
                self?.store.execute(.tagAdditionMenuTapped(clip.id))
            }

        case .addToAlbum:
            return UIAction(title: L10n.clipsListContextMenuAddToAlbum,
                            image: UIImage(systemName: "rectangle.stack.fill.badge.plus")) { [weak self] _ in
                self?.store.execute(.albumAdditionMenuTapped(clip.id))
            }

        case .reveal:
            return UIAction(title: L10n.clipsListContextMenuReveal,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                self?.store.execute(.revealMenuTapped(clip.id))
            }

        case .hide:
            return UIAction(title: L10n.clipsListContextMenuHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                self?.store.execute(.hideMenuTapped(clip.id))
            }

        case .removeFromAlbum:
            return UIAction(title: L10n.clipsListContextMenuRemoveFromAlbum,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.removeFromAlbumMenuTapped(clip.id, indexPath))
            }

        case .delete:
            return UIAction(title: L10n.clipsListContextMenuDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.deleteMenuTapped(clip.id, indexPath))
            }

        case .share:
            return UIAction(title: L10n.clipsListContextMenuShare,
                            image: UIImage(systemName: "square.and.arrow.up.fill")) { [weak self] _ in
                self?.store.execute(.shareMenuTapped(clip.id, indexPath))
            }

        case .purge:
            return UIAction(title: L10n.clipsListContextMenuPurge,
                            image: UIImage(systemName: "scissors"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.purgeMenuTapped(clip.id, indexPath))
            }

        case .edit:
            return UIAction(title: L10n.clipsListContextMenuEdit,
                            image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.store.execute(.editMenuTapped(clip.id))
            }
        }
    }
}

extension ClipCollectionViewController: ClipCollectionToolBarDelegate {
    // MARK: - ClipCollectionToolBarDelegate

    func didTriggered(_ event: ClipCollectionToolBarEvent) {
        store.execute(.toolBarEventOccurred(event))
    }
}

extension ClipCollectionViewController: ClipCollectionNavigationBarDelegate {
    // MARK: - ClipCollectionNavigationBarDelegate

    func didTriggered(_ event: ClipCollectionNavigationBarEvent) {
        store.execute(.navigationBarEventOccurred(event))
    }
}

extension ClipCollectionViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard let clip = dataSource.itemIdentifier(for: indexPath) else { return .zero }

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        case let (.some(item), .some, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipCollectionViewCell.secondaryStickingOutMargin

        case let (.some(item), .some, .some):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipCollectionViewCell.secondaryStickingOutMargin
                + ClipCollectionViewCell.tertiaryStickingOutMargin

        case let (.some(item), _, _):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        default:
            return width
        }
    }
}
