//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class NewAlbumListViewController: UIViewController {
    typealias Layout = AlbumListViewLayout
    typealias Store = LikePics.Store<AlbumListViewState, AlbumListViewAction, AlbumListViewDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private let emptyMessageView = EmptyMessageView()
    private let searchController = UISearchController(searchResultsController: nil)

    private let thumbnailLoader: ThumbnailLoaderProtocol
    private let menuBuilder: AlbumListMenuBuildable.Type

    // MARK: Component

    private let albumAdditionAlert: TextEditAlertController
    private let albumEditAlert: TextEditAlertController

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: AlbumListViewState,
         albumAdditionAlertState: TextEditAlertState,
         albumEditAlertState: TextEditAlertState,
         dependency: AlbumListViewDependency,
         thumbnailLoader: ThumbnailLoaderProtocol,
         menuBuilder: AlbumListMenuBuildable.Type)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: AlbumListViewReducer.self)
        self.albumAdditionAlert = .init(state: albumAdditionAlertState)
        self.albumEditAlert = .init(state: albumEditAlertState)

        self.thumbnailLoader = thumbnailLoader
        self.menuBuilder = menuBuilder

        super.init(nibName: nil, bundle: nil)

        albumAdditionAlert.textEditAlertDelegate = self
        albumEditAlert.textEditAlertDelegate = self
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
        configureSearchController()
        configureEmptyMessageView()

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        store.execute(.editingChanged(isEditing: editing))
    }
}

extension NewAlbumListViewController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.global().async {
                let items = state.albums.map { Layout.Item(album: $0, isEditing: state.isEditing) }
                Layout.apply(items: items, to: self.dataSource, in: self.collectionView)
            }

            self.collectionView.alpha = state.isCollectionViewDisplaying ? 1 : 0
            self.emptyMessageView.alpha = state.isEmptyMessageViewDisplaying ? 1 : 0
            self.navigationItem.leftBarButtonItem?.isEnabled = state.isAddButtonEnabled
            self.collectionView.dragInteractionEnabled = state.isDragInteractionEnabled

            self.presentAlertIfNeeded(for: state.alert)
        }
        .store(in: &subscriptions)
    }

    private func presentAlertIfNeeded(for alert: AlbumListViewState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .addition:
            albumAdditionAlert.present(with: "", validator: { $0?.isEmpty == false }, on: self)

        case let .renaming(albumId: _, title: title):
            albumEditAlert.present(with: title, validator: { $0?.isEmpty == false && $0 != title }, on: self)

        case let .deletion(albumId: _, title: title, at: indexPath):
            presentDeleteConfirmationAlert(title: title, indexPath: indexPath)

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

    private func presentDeleteConfirmationAlert(title: String, indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }

        let alert = UIAlertController(title: L10n.albumListViewAlertForDeleteTitle(title),
                                      message: L10n.albumListViewAlertForDeleteMessage(title),
                                      preferredStyle: .actionSheet)

        let confirmAction = UIAlertAction(title: L10n.albumListViewAlertForDeleteAction, style: .destructive) { [weak self] _ in
            self?.store.execute(.alertDeleteConfirmed)
        }
        let cancelAction = UIAlertAction(title: L10n.confirmAlertCancel, style: .cancel) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension NewAlbumListViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = ClipCollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
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
        dataSource = Layout.configureDataSource(collectionView: collectionView,
                                                thumbnailLoader: thumbnailLoader,
                                                delegate: self)
    }

    private func configureReorder() {
        dataSource.reorderingHandlers.canReorderItem = { [weak self] _ in self?.isEditing ?? false }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            let albumIds = transaction.finalSnapshot.itemIdentifiers.map { $0.album.id }
            self?.store.execute(.reordered(albumIds))
        }

        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    private func configureNavigationBar() {
        navigationItem.title = L10n.albumListViewTitle

        let addItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            self?.store.execute(.addButtonTapped)
        })

        navigationItem.leftBarButtonItem = addItem
        navigationItem.rightBarButtonItem = editButtonItem
    }

    private func configureSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = L10n.placeholderSearchTag
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func configureEmptyMessageView() {
        emptyMessageView.title = L10n.albumListViewEmptyTitle
        emptyMessageView.message = L10n.albumListViewEmptyMessage
        emptyMessageView.actionButtonTitle = L10n.albumListViewEmptyActionTitle
        emptyMessageView.isActionButtonHidden = true
    }
}

extension NewAlbumListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(item.album.identity))
    }
}

extension NewAlbumListViewController {
    // MARK: - UICollectionViewDelegate (Context Menu)

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = self.dataSource.itemIdentifier(for: indexPath), self.isEditing == false else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil,
                                          actionProvider: self.makeActionProvider(for: item.album, at: indexPath))
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

    private func makeActionProvider(for album: Album, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        let items = self.menuBuilder.build(for: album).map {
            self.makeAction(from: $0, for: album, at: indexPath)
        }
        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeAction(from item: AlbumList.MenuItem, for album: Album, at indexPath: IndexPath) -> UIAction {
        switch item {
        case .hide:
            return UIAction(title: L10n.albumListViewContextMenuActionHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                self?.store.execute(.hideMenuTapped(album.id))
            }

        case .reveal:
            return UIAction(title: L10n.albumListViewContextMenuActionReveal,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                self?.store.execute(.revealMenuTapped(album.id))
            }

        case .rename:
            return UIAction(title: L10n.albumListViewContextMenuActionUpdate,
                            image: UIImage(systemName: "text.cursor")) { [weak self] _ in
                self?.store.execute(.renameMenuTapped(album.id))
            }

        case .delete:
            return UIAction(title: L10n.albumListViewContextMenuActionDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.deleteMenuTapped(album.id, indexPath))
            }
        }
    }
}

extension NewAlbumListViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}

extension NewAlbumListViewController: AlbumListCollectionViewCellDelegate {
    // MARK: - AlbumListCollectionViewCellDelegate

    func didTapTitleEditButton(_ cell: AlbumListCollectionViewCell) {
        guard let albumId = cell.albumId else { return }
        store.execute(.editingTitleTapped(albumId))
    }

    func didTapRemover(_ cell: AlbumListCollectionViewCell) {
        // TODO: indexPath(for:) がうまく動かないケースがあるので修正する
        guard let albumId = cell.albumId, let indexPath = collectionView.indexPath(for: cell) else { return }
        store.execute(.removerTapped(albumId, indexPath))
    }
}

extension NewAlbumListViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return [] }
        let provider = NSItemProvider(object: item.album.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumListCollectionViewCell else { return nil }
        return Self.makePreviewParameter(for: cell)
    }
}

extension NewAlbumListViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return isEditing
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        // NOP
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumListCollectionViewCell else { return nil }
        return Self.makePreviewParameter(for: cell)
    }
}

// MARK: Drag & Drop

extension NewAlbumListViewController {
    static func makePreviewParameter(for cell: AlbumListCollectionViewCell) -> UIDragPreviewParameters {
        let parameters = UIDragPreviewParameters()
        // HACK: 左上のRemoverアイコンが見切れてしまうため、描画範囲を広げる
        let path: UIBezierPath = {
            let path = UIBezierPath()
            path.move(to: .init(x: -22, y: -22))
            path.addLine(to: .init(x: cell.frame.width, y: 0))
            path.addLine(to: .init(x: cell.frame.width, y: cell.frame.height))
            path.addLine(to: .init(x: -22, y: cell.frame.height))
            path.close()
            return path
        }()
        parameters.visiblePath = path
        parameters.backgroundColor = .clear
        // HACK: nilだとデフォルトの影が描画されてしまうため、空の BezierPath を指定する
        parameters.shadowPath = UIBezierPath()
        return parameters
    }
}

extension NewAlbumListViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
            }
        }
        return true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension NewAlbumListViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(searchController.searchBar.text ?? ""))
        }
    }
}

extension NewAlbumListViewController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.alertSaveButtonTapped(text: text))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}
