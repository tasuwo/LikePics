//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class ClipEditViewController: UIViewController {
    typealias Layout = ClipEditViewLayout
    typealias Store = LikePics.Store<ClipEditViewState, ClipEditViewAction, ClipEditViewDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private var proxy: Layout.Proxy!
    private lazy var interactionHandler: URLButtonInteractionHandler = {
        let handler = URLButtonInteractionHandler()
        handler.baseView = view
        return handler
    }()

    private let thumbnailLoader: ThumbnailLoaderProtocol

    // MARK: Component

    private let siteUrlEditAlert: TextEditAlertController

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: Temporary

    private var _previousItemsForSelection: Collection<ClipItem>?

    // MARK: - Initializers

    init(state: ClipEditViewState,
         siteUrlEditAlertState: TextEditAlertState,
         dependency: ClipEditViewDependency,
         thumbnailLoader: ThumbnailLoaderProtocol)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: ClipEditViewReducer.self)
        self.siteUrlEditAlert = .init(state: siteUrlEditAlertState)
        self.thumbnailLoader = thumbnailLoader

        super.init(nibName: nil, bundle: nil)

        siteUrlEditAlert.textEditAlertDelegate = self
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
        configureReorder()
        configureNavigationBar()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

extension ClipEditViewController {
    func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.global().async {
                let snapshot = Self.createSnapshot(state)
                self.dataSource.apply(snapshot)
            }

            self.collectionView.isEditing = state.isItemsEditing

            self.applySelections(for: state)
            self.presentAlertIfNeeded(for: state.alert)

            if state.isDismissed {
                self.dismiss(animated: true, completion: nil)
            }
        }
        .store(in: &subscriptions)
    }

    private static func createSnapshot(_ state: ClipEditViewState) -> Layout.Snapshot {
        var snapshot = Layout.Snapshot()

        snapshot.appendSections([.tag])
        let tags = state.tags.displayableValues
            .map { Layout.Item.tag($0) }
        snapshot.appendItems([.tagAddition] + tags)

        snapshot.appendSections([.meta])
        let dataSize = ByteCountFormatter.string(fromByteCount: Int64(state.clip.dataSize), countStyle: .binary)
        snapshot.appendItems([
            .meta(.init(title: L10n.clipEditViewHiddenTitle, accessory: .switch(isOn: state.clip.isHidden))),
            .meta(.init(title: L10n.clipEditViewClipDataSizeTitle, accessory: .label(title: dataSize)))
        ])

        let items = state.items.displayableValues
            .map { Layout.Item.clipItem($0.map(to: Layout.ClipItem.self)) }
        snapshot.appendSections([.clipItem])
        snapshot.appendItems(items)

        snapshot.appendSections([.footer])
        snapshot.appendItems([.deleteClip])

        return snapshot
    }

    private func applySelections(for state: ClipEditViewState) {
        defer { _previousItemsForSelection = state.items }

        state.items.selections(from: _previousItemsForSelection)
            .map { $0.map(to: Layout.ClipItem.self) }
            .map { Layout.Item.clipItem($0) }
            .compactMap { self.dataSource.indexPath(for: $0) }
            .forEach { self.collectionView.selectItem(at: $0, animated: false, scrollPosition: []) }

        state.items.deselections(from: _previousItemsForSelection)
            .map { $0.map(to: Layout.ClipItem.self) }
            .map { Layout.Item.clipItem($0) }
            .compactMap { self.dataSource.indexPath(for: $0) }
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
    }

    private func presentAlertIfNeeded(for alert: ClipEditViewState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case let .siteUrlEdit(itemIds: _, title: title):
            siteUrlEditAlert.present(with: title ?? "", validator: { $0?.isEmpty == false && $0 != title && $0?.isUrlConvertible == true }, on: self)

        case let .deleteConfirmation(indexPath):
            presentDeleteConfirmationAlert(at: indexPath)

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

    private func presentDeleteConfirmationAlert(at indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            store.execute(.alertDismissed)
            return
        }

        let alert = UIAlertController(title: L10n.clipEditViewAlertForDeleteClipTitle,
                                      message: L10n.clipEditViewAlertForDeleteClipMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipEditViewDeleteClipItemTitle
        alert.addAction(.init(title: title, style: .destructive, handler: { [weak self] _ in
            self?.store.execute(.clipDeleteConfirmed)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }
}

extension ClipEditViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout(delegate: self))
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelectionDuringEditing = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        // swiftlint:disable identifier_name
        let (_dataSource, _proxy) = Layout.createDataSource(collectionView: collectionView, thumbnailLoader: thumbnailLoader)
        dataSource = _dataSource
        proxy = _proxy
        proxy.delegate = self
        proxy.interactionDelegate = interactionHandler
        collectionView.delegate = self
    }

    private func configureReorder() {
        collectionView.dragInteractionEnabled = true
        dataSource.reorderingHandlers.canReorderItem = { [weak self] item in
            item.canReorder && self?.collectionView.isEditing == false
        }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            let orderedItemIds: [ClipItem.Identity] = transaction.finalSnapshot.itemIdentifiers
                .compactMap { item -> Layout.ClipItem? in
                    switch item {
                    case let .clipItem(value):
                        return value

                    default:
                        return nil
                    }
                }
                .map { $0.itemId }
            self?.store.execute(.itemsReordered(orderedItemIds))
        }
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    private func configureNavigationBar() {
        title = L10n.clipEditViewTitle

        let doneItem = UIBarButtonItem(systemItem: .done, primaryAction: .init(handler: { [weak self] _ in
            self?.store.execute(.doneButtonTapped)
        }), menu: nil)
        navigationItem.rightBarButtonItem = doneItem
    }
}

extension ClipEditViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return false }
        switch item {
        case .deleteClip:
            return true

        case .clipItem where collectionView.isEditing:
            return true

        default:
            return false
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .deleteClip:
            store.execute(.clipDeletionButtonTapped(indexPath))

        case let .clipItem(item):
            store.execute(.itemSelected(item.itemId))

        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case let .clipItem(item):
            store.execute(.itemDeselected(item.itemId))

        default:
            break
        }
    }
}

extension ClipEditViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = dataSource.itemIdentifier(for: indexPath), case let .clipItem(clipItem) = item else { return [] }
        let provider = NSItemProvider(object: clipItem.itemId.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = indexPath
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension ClipEditViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let sectionValue = destinationIndexPath?.section,
              let section = ClipEditViewLayout.Section(rawValue: sectionValue),
              section == .clipItem
        else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
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

extension ClipEditViewController: ClipEditViewDelegate {
    // MARK: - ClipEditViewDelegate

    func trailingSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard store.stateValue.isItemDeletionEnabled else { return nil }
        guard case let .clipItem(item) = dataSource.itemIdentifier(for: indexPath) else { return nil }

        let deleteAction = UIContextualAction(style: .destructive,
                                              title: L10n.clipEditViewDeleteClipItemTitle) { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.store.execute(.itemDeletionActionOccurred(item.itemId, completion: completion))
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool) {
        guard case .meta = self.dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.clipHidesSwitchChanged(isOn: isOn))
    }

    func didTapTagAdditionButton(_ cell: UICollectionViewCell) {
        store.execute(.tagAdditionButtonTapped)
    }

    func didTapTagDeletionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              case let .tag(tag) = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.tagDeletionButtonTapped(tag.id))
    }

    func didTapSiteUrl(_ sender: UIView, url: URL?) {
        store.execute(.itemSiteUrlButtonTapped(url))
    }

    func didTapSiteUrlEditButton(_ sender: UIView, url: URL?) {
        guard let cell = sender.next(ofType: UICollectionViewCell.self),
              let indexPath = collectionView.indexPath(for: cell),
              case let .clipItem(clipItem) = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.itemSiteUrlEditButtonTapped(clipItem.itemId))
    }

    func didTapSelectionButton() {
        store.execute(.itemsEditButtonTapped)
    }

    func didTapCancelSelectionButton() {
        store.execute(.itemsEditCancelButtonTapped)
    }

    func didTapEditSiteUrlsForSelectionButton() {
        store.execute(.itemsSiteUrlsEditButtonTapped)
    }
}

extension ClipEditViewController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.siteUrlEditConfirmed(text: text))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}

extension ClipEditViewController: UIAdaptivePresentationControllerDelegate {
    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.execute(.didDismissedManually)
    }
}

private extension ClipItem {
    func map(to: ClipEditViewLayout.ClipItem.Type) -> ClipEditViewLayout.ClipItem {
        return .init(itemId: id,
                     imageId: imageId,
                     imageUrl: imageUrl,
                     siteUrl: url,
                     dataSize: Double(imageDataSize),
                     imageHeight: imageSize.height,
                     imageWidth: imageSize.width)
    }
}
