//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import Smoothie
import TBoxUIKit
import UIKit

class ClipItemListViewController: UIViewController {
    typealias Layout = ClipItemListViewLayout
    typealias Store = ForestKit.Store<ClipItemListState, ClipItemListAction, ClipItemListDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Service

    private let thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipItemListState,
         dependency: ClipItemListDependency,
         thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: ClipItemListReducer())
        self.thumbnailLoader = thumbnailLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureReorder()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipItemListViewController {
    func bind(to store: Store) {
        store.state
            .removeDuplicates(by: {
                $0.items.filteredOrderedEntities() == $1.items.filteredOrderedEntities()
            })
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                let snapshot = Self.createSnapshot(items: state.items.orderedFilteredEntities())
                self?.dataSource.apply(snapshot, animatingDifferences: true)
                self?.updateCellAppearance()
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] in self?.presentAlertIfNeeded(for: $0) }
            .store(in: &subscriptions)
    }

    // MARK: Snapshot

    private static func createSnapshot(items: [ClipItem]) -> Layout.Snapshot {
        var snapshot = Layout.Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(zip(items.indices, items).map { Layout.Item($1, at: $0 + 1) })

        return snapshot
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: ClipItemListState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case let .deletion(item):
            presentDeletionAlert(for: item)

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

    private func presentDeletionAlert(for item: ClipItem) {
        guard let indexPath = dataSource.indexPath(for: .init(item, at: 0)), // index は比較に利用されないので適当な値で埋める
              let cell = collectionView.cellForItem(at: indexPath)
        else {
            store.execute(.alertDismissed)
            return
        }

        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipInformationAlertForDeleteAction
        alert.addAction(.init(title: title, style: .destructive, handler: { [weak self] _ in
            self?.store.execute(.alertDeleteConfirmed)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }

    // MARK: Appearance

    private func updateCellAppearance() {
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
            guard let cell = collectionView.cellForItem(at: indexPath) as? ClipItemCell else { return }

            guard var configuration = cell.contentConfiguration as? ClipItemContentConfiguration else { return }
            configuration.page = item.order
            configuration.numberOfPage = store.stateValue.items._entities.count
            cell.contentConfiguration = configuration
        }
    }
}

// MARK: - Configuration

extension ClipItemListViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self

        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        dataSource = Layout.configureDataSource(collectionView, thumbnailLoader)
    }

    private func configureReorder() {
        collectionView.dragInteractionEnabled = true
        dataSource.reorderingHandlers.canReorderItem = { _ in true }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            let itemIds = transaction.finalSnapshot.itemIdentifiers.map { $0.itemId }
            self?.store.execute(.reordered(itemIds))
        }
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
}

extension ClipItemListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(item.itemId))
    }
}

extension ClipItemListViewController {
    // MARK: - UICollectionViewDelegate (Context Menu)

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              let clipItem = store.stateValue.items.entity(having: item.itemId) else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil,
                                          actionProvider: makeActionProvider(for: clipItem, at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration, collectionView: UICollectionView) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? NSIndexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: identifier as IndexPath) else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = UIBezierPath()
        return UITargetedPreview(view: cell, parameters: parameters)
    }

    private func makeActionProvider(for clipItem: ClipItem, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        let items = ClipItemListMenuBuilder.build(for: clipItem).map {
            makeElement(from: $0, for: clipItem, at: indexPath)
        }
        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeElement(from item: ClipItemListMenuItem, for clipItem: ClipItem, at indexPath: IndexPath) -> UIMenuElement {
        switch item {
        case .delete:
            return UIAction(title: L10n.clipInformationContextMenuDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.deleteMenuTapped(clipItem.id))
            }

        case .copyImageUrl:
            return UIAction(title: L10n.clipInformationContextMenuCopyImageUrl,
                            image: UIImage(systemName: "doc.on.doc"),
                            attributes: []) { [weak self] _ in
                self?.store.execute(.copyImageUrlMenuTapped(clipItem.id))
            }

        case .openImageUrl:
            return UIAction(title: L10n.clipInformationContextMenuOpenImageUrl,
                            image: UIImage(systemName: "globe"),
                            attributes: []) { [weak self] _ in
                self?.store.execute(.openImageUrlMenuTapped(clipItem.id))
            }
        }
    }
}

extension ClipItemListViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return [] }
        let provider = NSItemProvider(object: item.itemId.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension ClipItemListViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        // NOP
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension ClipItemListViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var previewingCellCornerRadius: CGFloat {
        return 8
    }

    var previewingCollectionView: UICollectionView { collectionView }

    func previewingCell(id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool) -> ClipPreviewPresentableCell? {
        guard let item = store.stateValue.items._entities[id.itemId],
              let indexPath = dataSource.indexPath(for: .init(item.value, at: item.index + 1)) else { return nil }

        if needsScroll {
            // セルが画面外だとインスタンスを取り出せないので、表示する
            displayPreviewingCell(id: id)
        }

        return collectionView.cellForItem(at: indexPath) as? ClipItemCell
    }

    func displayPreviewingCell(id: ClipPreviewPresentableCellIdentifier) {
        guard let item = store.stateValue.items._entities[id.itemId],
              let indexPath = dataSource.indexPath(for: .init(item.value, at: item.index + 1)) else { return }

        // collectionViewのみでなくviewも再描画しないとセルの座標系がおかしくなる
        // また、scrollToItem呼び出し前に一度再描画しておかないと、正常にスクロールができないケースがある
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)

        // スクロール後に再描画しないと、セルの座標系が更新されない
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
    }

    var isDisplayablePrimaryThumbnailOnly: Bool { false }
}