//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import Smoothie
import UIKit

class AlbumListViewController: UIViewController {
    typealias Layout = AlbumListViewLayout
    typealias Store = CompositeKit.Store<AlbumListViewState, AlbumListViewAction, AlbumListViewDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private let emptyMessageView = EmptyMessageView()
    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: Component

    private let albumAdditionAlert: TextEditAlertController
    private let albumEditAlert: TextEditAlertController

    // MARK: Service

    private let thumbnailPipeline: Pipeline
    private let imageQueryService: ImageQueryServiceProtocol
    private let menuBuilder: AlbumListMenuBuildable.Type

    // MARK: Store/Subscription

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private let albumsUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.AlbumListViewController", qos: .background)

    // MARK: State Restoration

    private var viewDidAppeared: CurrentValueSubject<Bool, Never> = .init(false)
    private var presentingAlert: UIViewController?

    // MARK: - Initializers

    init(state: AlbumListViewState,
         albumAdditionAlertState: TextEditAlertState,
         albumEditAlertState: TextEditAlertState,
         dependency: AlbumListViewDependency,
         thumbnailPipeline: Pipeline,
         imageQueryService: ImageQueryServiceProtocol,
         menuBuilder: AlbumListMenuBuildable.Type)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: AlbumListViewReducer())
        self.albumAdditionAlert = .init(state: albumAdditionAlertState)
        self.albumEditAlert = .init(state: albumEditAlertState)

        self.thumbnailPipeline = thumbnailPipeline
        self.imageQueryService = imageQueryService
        self.menuBuilder = menuBuilder

        super.init(nibName: nil, bundle: nil)

        albumAdditionAlert.textEditAlertDelegate = self
        albumEditAlert.textEditAlertDelegate = self
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
        configureNavigationBar()
        configureSearchController()
        configureEmptyMessageView()

        bind(to: store)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateUserActivity(store.stateValue)
        viewDidAppeared.send(true)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        store.execute(.viewWillLayoutSubviews)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        store.execute(.editingChanged(isEditing: editing))
    }
}

// MARK: - Bind

extension AlbumListViewController {
    private func bind(to store: Store) {
        store.state
            .receive(on: albumsUpdateQueue)
            .removeDuplicates(by: { $0.filteredOrderedAlbums == $1.filteredOrderedAlbums && $0.isEditing == $1.isEditing })
            .sink { [weak self] state in
                guard let self = self else { return }
                let items = state.orderedFilteredAlbums.map { Layout.Item(album: $0, isEditing: state.isEditing) }
                Layout.apply(items: items, to: self.dataSource, in: self.collectionView)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.searchQuery) { [weak self] query in
                self?.searchController.set(text: query)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.emptyMessageViewAlpha, to: \.alpha, on: emptyMessageView)
            .store(in: &subscriptions)
        store.state
            .bind(\.collectionViewAlpha, to: \.alpha, on: collectionView)
            .store(in: &subscriptions)
        store.state
            .bind(\.isSearchBarEnabled) { [weak self] isEnabled in
                self?.searchController.set(isEnabled: isEnabled)
            }
            .store(in: &subscriptions)

        store.state
            .bindNoRetain(\.isEditing, to: \.isEditing, on: self)
            .store(in: &subscriptions)

        store.state
            .bind(\.isAddButtonEnabled) { [weak self] isEnabled in
                self?.navigationItem.leftBarButtonItem?.isEnabled = isEnabled
            }
            .store(in: &subscriptions)
        store.state
            .bind(\.isEditButtonEnabled, to: \.isEnabled, on: editButtonItem)
            .store(in: &subscriptions)
        store.state
            .bind(\.isDragInteractionEnabled, to: \.dragInteractionEnabled, on: collectionView)
            .store(in: &subscriptions)

        store.state
            .waitUntilToBeTrue(viewDidAppeared)
            .removeDuplicates(by: \.alert)
            .sink { [weak self] state in self?.presentAlertIfNeeded(for: state) }
            .store(in: &subscriptions)

        store.state
            .receive(on: DispatchQueue.global())
            .map({ $0.removingSessionStates() })
            .removeDuplicates()
            .debounce(for: 1, scheduler: DispatchQueue.global())
            .sink { [weak self] state in self?.updateUserActivity(state) }
            .store(in: &subscriptions)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for state: AlbumListViewState) {
        switch state.alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .addition:
            albumAdditionAlert.present(with: "", validator: { $0?.isEmpty == false }, on: self)

        case let .renaming(albumId: _, title: title):
            albumEditAlert.present(with: title, validator: { $0?.isEmpty == false && $0 != title }, on: self)

        case let .deletion(albumId: albumId, title: title):
            presentDeleteConfirmationAlert(for: albumId, title: title, state: state)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        presentingAlert = alert
        self.present(alert, animated: true, completion: nil)
    }

    private func presentDeleteConfirmationAlert(for albumId: Album.Identity, title: String, state: AlbumListViewState) {
        guard let album = state.albums.entity(having: albumId),
              let indexPath = dataSource.indexPath(for: .init(album: album, isEditing: state.isEditing)),
              let cell = collectionView.cellForItem(at: indexPath)
        else {
            store.execute(.alertDismissed)
            return
        }

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

        presentingAlert = alert
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: User Activity

    private func updateUserActivity(_ state: AlbumListViewState) {
        DispatchQueue.global().async {
            guard let activity = NSUserActivity.make(with: .albums(state.removingSessionStates())) else { return }
            DispatchQueue.main.async { self.view.window?.windowScene?.userActivity = activity }
        }
    }
}

// MARK: - Configuration

extension AlbumListViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        collectionView = ClipCollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelectionDuringEditing = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        // HACK: UISVCでSearchControllerが非表示になってしまうことがあるため、
        //       応急処置としてスクロール可能にしておく
        collectionView.alwaysBounceVertical = true
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
                                                thumbnailPipeline: thumbnailPipeline,
                                                queryService: imageQueryService,
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
        // イベント発火を避けるためにdelegate設定前にリストアする必要がある
        searchController.searchBar.text = store.stateValue.searchQuery

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = L10n.placeholderSearchAlbum
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func configureEmptyMessageView() {
        emptyMessageView.title = L10n.albumListViewEmptyTitle
        emptyMessageView.message = L10n.albumListViewEmptyMessage
        emptyMessageView.actionButtonTitle = L10n.albumListViewEmptyActionTitle
        emptyMessageView.isActionButtonHidden = false
        emptyMessageView.delegate = self
    }
}

extension AlbumListViewController: UICollectionViewDelegate {
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

extension AlbumListViewController {
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

    private func makeAction(from item: AlbumListMenuItem, for album: Album, at indexPath: IndexPath) -> UIAction {
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
                self?.store.execute(.deleteMenuTapped(album.id))
            }
        }
    }
}

extension AlbumListViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}

extension AlbumListViewController: AlbumListCollectionViewCellDelegate {
    // MARK: - AlbumListCollectionViewCellDelegate

    func didTapTitleEditButton(_ cell: AlbumListCollectionViewCell) {
        guard let albumId = cell.albumId else { return }
        store.execute(.editingTitleTapped(albumId))
    }

    func didTapRemover(_ cell: AlbumListCollectionViewCell) {
        guard let albumId = cell.albumId else { return }
        store.execute(.removerTapped(albumId))
    }
}

extension AlbumListViewController: UICollectionViewDragDelegate {
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

extension AlbumListViewController: UICollectionViewDropDelegate {
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

extension AlbumListViewController {
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

extension AlbumListViewController: UISearchBarDelegate {
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

extension AlbumListViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(searchController.searchBar.text ?? ""))
        }
    }
}

extension AlbumListViewController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.alertSaveButtonTapped(text: text))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}

extension AlbumListViewController: Restorable {
    // MARK: - Restorable

    func restore() -> RestorableViewController {
        var nextState = store.stateValue
        nextState.isPreparedQueryEffects = false

        let nextAlbums = nextState.albums.updated(entities: [])
        nextState.albums = nextAlbums

        presentingAlert?.dismiss(animated: false, completion: nil)
        albumAdditionAlert.dismiss(animated: false, completion: nil)
        albumEditAlert.dismiss(animated: false, completion: nil)

        return AlbumListViewController(state: nextState,
                                       albumAdditionAlertState: albumAdditionAlert.store.stateValue,
                                       albumEditAlertState: albumEditAlert.store.stateValue,
                                       dependency: store.dependency,
                                       thumbnailPipeline: thumbnailPipeline,
                                       imageQueryService: imageQueryService,
                                       menuBuilder: menuBuilder)
    }
}
