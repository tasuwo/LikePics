//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import Smoothie
import UIKit

public class AlbumSelectionModalController: UIViewController {
    typealias Layout = AlbumSelectionModalLayout
    typealias Store = CompositeKit.Store<AlbumSelectionModalState, AlbumSelectionModalAction, AlbumSelectionModalDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private let emptyMessageView = EmptyMessageView()
    private var dataSource: Layout.DataSource!
    private var quickAddButton = UIButton()

    // MARK: Component

    private let albumAdditionAlert: TextEditAlertController

    // MARK: Service

    private let thumbnailProcessingQueue: ImageProcessingQueue
    private let imageQueryService: ImageQueryServiceProtocol

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private let collectionUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.AlbumSelectionModalController")

    // MARK: - Initializers

    public init(
        state: AlbumSelectionModalState,
        albumAdditionAlertState: TextEditAlertState,
        dependency: AlbumSelectionModalDependency,
        thumbnailProcessingQueue: ImageProcessingQueue,
        imageQueryService: ImageQueryServiceProtocol
    ) {
        self.store = .init(initialState: state, dependency: dependency, reducer: AlbumSelectionModalReducer())
        self.albumAdditionAlert = .init(state: albumAdditionAlertState)
        self.thumbnailProcessingQueue = thumbnailProcessingQueue
        self.imageQueryService = imageQueryService
        super.init(nibName: nil, bundle: nil)

        albumAdditionAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        store.execute(.viewDidDisappear)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureSearchBar()
        configureNavigationBar()
        configureEmptyMessageView()
        configureKeybinding()

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override public func viewDidAppear(_ animated: Bool) {
        searchBar.becomeFirstResponder()
    }
}

// MARK: - Bind

extension AlbumSelectionModalController {
    private func bind(to store: Store) {
        store.state
            .receive(on: collectionUpdateQueue)
            .removeDuplicates(by: { $0.filteredOrderedAlbums == $1.filteredOrderedAlbums })
            .sink { [weak self] state in
                var snapshot = Layout.Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(state.orderedFilteredAlbums)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
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

        store.state
            .sink { [weak self] state in
                guard let title = state.quickAddButtonTitle, !state.isQuickAddButtonHidden else {
                    self?.quickAddButton.configuration?.title = ""
                    self?.quickAddButton.alpha = 0
                    return
                }
                self?.quickAddButton.configuration?.title = title
                self?.quickAddButton.alpha = 1
            }
            .store(in: &subscriptions)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: AlbumSelectionModalState.Alert?) {
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
        alert.addAction(
            .init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
                self?.store.execute(.alertDismissed)
            }
        )
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension AlbumSelectionModalController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        searchBar = UISearchBar()
        searchBar.backgroundColor = .clear
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyMessageView)
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))

        let quickAddButton = UIButton(
            primaryAction: .init { [weak self] _ in
                self?.store.execute(.quickAddButtonTapped)
            }
        )
        var configuration = UIButton.Configuration.plain()
        configuration.title = ""
        quickAddButton.configuration = configuration
        quickAddButton.isPointerInteractionEnabled = true
        quickAddButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(quickAddButton)
        NSLayoutConstraint.activate([
            quickAddButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            quickAddButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
        ])
        self.quickAddButton = quickAddButton
    }

    private func configureDataSource() {
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        dataSource = Layout.createDataSource(collectionView, thumbnailProcessingQueue, imageQueryService)
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

        let addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.addButtonTapped)
            }),
            menu: nil
        )

        navigationItem.leftBarButtonItem = addItem
    }

    private func configureEmptyMessageView() {
        emptyMessageView.alpha = 0
        emptyMessageView.title = L10n.albumListViewEmptyTitle
        emptyMessageView.message = L10n.albumListViewEmptyMessage
        emptyMessageView.actionButtonTitle = L10n.albumListViewEmptyActionTitle
        emptyMessageView.delegate = self
    }

    private func configureKeybinding() {
        addKeyCommand(UIKeyCommand(title: L10n.keyCommandAdd, action: #selector(handle(key:)), input: "n", modifierFlags: .command))
    }

    @objc func handle(key: UIKeyCommand?) {
        switch key?.input {
        case "n": store.execute(.addButtonTapped)
        default: break
        }
    }
}

extension AlbumSelectionModalController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(album.identity))
    }
}

extension AlbumSelectionModalController: UISearchBarDelegate {
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

extension AlbumSelectionModalController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}

extension AlbumSelectionModalController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    public func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.alertSaveButtonTapped(text: text))
    }

    public func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}

extension AlbumSelectionModalController: UIAdaptivePresentationControllerDelegate {
    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.execute(.didDismissedManually)
    }
}

extension AlbumSelectionModalController: ModalController {
    // MARK: - ModalController

    public var id: UUID { store.stateValue.id }
}
