//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import Smoothie
import UIKit

public class AlbumMultiSelectionModalController: UIViewController {
    typealias Layout = AlbumMultiSelectionModalLayout
    typealias Store = CompositeKit.Store<AlbumMultiSelectionModalState, AlbumMultiSelectionModalAction, AlbumMultiSelectionModalDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private let emptyMessageView = EmptyMessageView()
    private var dataSource: Layout.DataSource!
    private var selectionApplier: UICollectionViewSelectionLazyApplier<Layout.Section, Layout.Item, ListingAlbumTitle>!

    // MARK: Component

    private let albumAdditionAlert: TextEditAlertController

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private let collectionUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.AlbumMultiSelectionModalController")

    // MARK: - Initializers

    public init(state: AlbumMultiSelectionModalState,
                albumAdditionAlertState: TextEditAlertState,
                dependency: AlbumMultiSelectionModalDependency)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: AlbumMultiSelectionModalReducer())
        self.albumAdditionAlert = .init(state: albumAdditionAlertState)
        super.init(nibName: nil, bundle: nil)

        albumAdditionAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureSearchBar()
        configureNavigationBar()
        configureEmptyMessageView()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension AlbumMultiSelectionModalController {
    private func bind(to store: Store) {
        store.state
            .receive(on: collectionUpdateQueue)
            .removeDuplicates(by: { $0.filteredOrderedAlbums == $1.filteredOrderedAlbums })
            .sink { [weak self] state in
                guard let self = self else { return }
                var snapshot = Layout.Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(state.orderedFilteredAlbums)
                self.dataSource.apply(snapshot, animatingDifferences: true)
                self.selectionApplier.didApplyDataSource(snapshot: state.albums)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isCollectionViewHidden, to: \.isHidden, on: searchBar)
            .store(in: &subscriptions)
        store.state
            .bind(\.isCollectionViewHidden, to: \.isHidden, on: collectionView)
            .store(in: &subscriptions)

        store.state
            .bind(\.emptyMessageViewAlpha, to: \.alpha, on: emptyMessageView)
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.albums._selectedIds)
            .sink { [weak self] state in self?.selectionApplier.applySelection(snapshot: state.albums) }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in
                self?.presentAlertIfNeeded(for: alert)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismissAll(completion: nil)
            }
            .store(in: &subscriptions)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: AlbumMultiSelectionModalState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .addition:
            albumAdditionAlert.present(with: "", validator: { $0?.isEmpty == false }, on: self)

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
}

// MARK: - Configuration

extension AlbumMultiSelectionModalController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        searchBar = UISearchBar()
        searchBar.backgroundColor = .clear
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyMessageView)
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        dataSource = Layout.createDataSource(collectionView)
        selectionApplier = UICollectionViewSelectionLazyApplier(collectionView: collectionView, dataSource: dataSource) { $0 }
    }

    private func configureSearchBar() {
        searchBar.barStyle = .default
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        searchBar.placeholder = L10n.placeholderSearchAlbum
        searchBar.backgroundColor = Asset.Color.background.color
    }

    private func configureNavigationBar() {
        navigationItem.title = L10n.albumSelectionViewTitle

        let addItem = UIBarButtonItem(systemItem: .add, primaryAction: .init(handler: { [weak self] _ in
            self?.store.execute(.addButtonTapped)
        }), menu: nil)
        let saveItem = UIBarButtonItem(systemItem: .save, primaryAction: .init(handler: { [weak self] _ in
            self?.store.execute(.saveButtonTapped)
        }), menu: nil)
        [addItem, saveItem].forEach {
            // HACK: ShareExtentionだと、tintColorがテキスト色にうまく反映されないケースがあるので、ここで反映する
            $0.setTitleTextAttributes([.foregroundColor: Asset.Color.likePicsRed.color], for: .normal)
            $0.setTitleTextAttributes([.foregroundColor: Asset.Color.likePicsRed.color.withAlphaComponent(0.4)], for: .disabled)
        }
        navigationItem.leftBarButtonItem = addItem
        navigationItem.rightBarButtonItem = saveItem
    }

    private func configureEmptyMessageView() {
        emptyMessageView.alpha = 0
        emptyMessageView.title = L10n.albumListViewEmptyTitle
        emptyMessageView.message = L10n.albumListViewEmptyMessage
        emptyMessageView.actionButtonTitle = L10n.albumListViewEmptyActionTitle
        emptyMessageView.delegate = self
    }
}

extension AlbumMultiSelectionModalController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(album.identity))
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let album = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.deselected(album.identity))
    }
}

extension AlbumMultiSelectionModalController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
        }
    }

    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
            }
        }
        return true
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension AlbumMultiSelectionModalController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}

extension AlbumMultiSelectionModalController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    public func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.alertSaveButtonTapped(text: text))
    }

    public func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}

extension AlbumMultiSelectionModalController: UIAdaptivePresentationControllerDelegate {
    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.execute(.didDismissedManually)
    }
}

extension AlbumMultiSelectionModalController: ModalController {
    // MARK: - ModalController

    public var id: UUID { store.stateValue.id }
}
