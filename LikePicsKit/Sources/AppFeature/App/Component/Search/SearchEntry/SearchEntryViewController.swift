//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import LikePicsUIKit
import Smoothie
import UIKit

class SearchEntryViewController: UIViewController {
    typealias RootStore = CompositeKit.Store<SearchViewRootState, SearchViewRootAction, SearchViewRootDependency>

    typealias Layout = SearchEntryViewLayout
    typealias Store = AnyStoring<SearchEntryViewState, SearchEntryViewAction, SearchEntryViewDependency>

    // MARK: - Properties

    // MARK: View

    let resultsController: SearchResultViewController
    private var searchController: UISearchController { resultsController.searchController }
    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Store

    private let rootStore: RootStore

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private let collectionUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.SearchEntryViewController")

    // MARK: State Restoration

    private let appBundle: Bundle
    private let viewDidAppeared: CurrentValueSubject<Bool, Never> = .init(false)
    private var presentingAlert: UIViewController?

    // MARK: - Initializers

    init(state: SearchViewRootState,
         dependency: SearchViewRootDependency,
         thumbnailProcessingQueue: ImageProcessingQueue,
         imageQueryService: ImageQueryServiceProtocol,
         appBundle: Bundle)
    {
        rootStore = CompositeKit.Store(initialState: state, dependency: dependency, reducer: searchViewRootReducer)
        store = rootStore
            .proxy(SearchViewRootState.entryMapping, SearchViewRootAction.entryMapping)
            .eraseToAnyStoring()
        let resultStore: SearchResultViewController.Store = rootStore
            .proxy(SearchViewRootState.resultMapping, SearchViewRootAction.resultMapping)
            .eraseToAnyStoring()
        resultsController = SearchResultViewController(store: resultStore,
                                                       thumbnailProcessingQueue: thumbnailProcessingQueue,
                                                       imageQueryService: imageQueryService)
        self.appBundle = appBundle

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resultsController.entryViewDidAppear(animated)
        updateUserActivity(rootStore.stateValue)
        viewDidAppeared.send(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.searchEntryViewTitle

        configureViewHierarchy()
        configureDataSource()
        configureSearchController()

        bind(to: rootStore)
        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // リストア時には自動でアクティブにならないため、手動でアクティブにする
        if rootStore.stateValue.shouldShowResultsView {
            searchController.isActive = true
        }
    }
}

// MARK: - Bind (Root)

extension SearchEntryViewController {
    private func bind(to store: RootStore) {
        store.state
            .receive(on: DispatchQueue.global())
            .debounce(for: 1, scheduler: DispatchQueue.global())
            .map({ $0.removingSessionStates() })
            .removeDuplicates()
            .sink { [weak self] state in self?.updateUserActivity(state) }
            .store(in: &subscriptions)
    }

    // MARK: User Activity

    private func updateUserActivity(_ state: SearchViewRootState) {
        DispatchQueue.global().async {
            guard let activity = NSUserActivity.make(with: .search(state.removingSessionStates()), appBundle: self.appBundle) else { return }
            DispatchQueue.main.async { self.view.window?.windowScene?.userActivity = activity }
        }
    }
}

// MARK: - Bind

extension SearchEntryViewController {
    private func bind(to store: Store) {
        store.state
            .receive(on: collectionUpdateQueue)
            .removeDuplicates(by: { $0.searchHistories == $1.searchHistories && $0.isSomeItemsHidden && $1.isSomeItemsHidden })
            .sink { [weak self] state in
                self?.applySnapshot(searchHistories: state.searchHistories, isSomeItemsHidden: state.isSomeItemsHidden)
            }
            .store(in: &subscriptions)

        store.state
            .waitUntilToBeTrue(viewDidAppeared)
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
            .store(in: &subscriptions)
    }

    // MARK: Snapshot

    private func applySnapshot(searchHistories: [Domain.ClipSearchHistory], isSomeItemsHidden: Bool) {
        var snapshot = Layout.Snapshot()

        snapshot.appendSections([.main])

        snapshot.appendItems([.historyHeader(enabledRemoveAllButton: !searchHistories.isEmpty)])

        if searchHistories.isEmpty {
            snapshot.appendItems([.empty], toSection: .main)
        } else {
            let histories = searchHistories
                .map { Layout.Item.history(.init(isSomeItemsHidden: isSomeItemsHidden, original: $0)) }
            snapshot.appendItems(histories, toSection: .main)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: SearchEntryViewState.Alert?) {
        switch alert {
        case .removeAll:
            presentRemoveAllConfirmationAlert()

        case .none:
            break
        }
    }

    private func presentRemoveAllConfirmationAlert() {
        let alert = UIAlertController(title: "", message: L10n.searchHistoryRemoveAllConfirmationMessage, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.searchHistoryRemoveAllConfirmationAction, style: .destructive, handler: { [weak self] _ in
            self?.store.execute(.alertDeleteConfirmed)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))
        presentingAlert = alert
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension SearchEntryViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        let layout = Layout.createLayout(historyDeletionHandler: { [weak self] indexPath -> UISwipeActionsConfiguration? in
            guard let self = self else { return nil }
            guard case let .history(history) = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            let deleteAction = UIContextualAction(style: .destructive, title: L10n.searchHistoryDeleteAction) { _, _, completion in
                self.store.execute(.removedHistory(history.original, completion: completion))
            }
            return UISwipeActionsConfiguration(actions: [deleteAction])
        })

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        // swiftlint:disable identifier_name
        let _dataSource = Layout.createDataSource(collectionView: collectionView,
                                                  removeAllHistoriesHandler: { [weak self] in
                                                      self?.store.execute(.removeAllHistories)
                                                  })
        dataSource = _dataSource
        collectionView.delegate = self
    }

    private func configureSearchController() {
        let filterButtonItem = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"),
                                               style: .plain,
                                               target: nil,
                                               action: nil)
        navigationItem.rightBarButtonItem = filterButtonItem
        resultsController.filterButtonItem = filterButtonItem

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = false

        searchController.searchBar.placeholder = L10n.placeholderSearchUniversal
        searchController.searchBar.searchTextField.allowsCopyingTokens = true
        searchController.searchBar.searchTextField.allowsDeletingTokens = true

        definesPresentationContext = true

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true

        searchController.showsSearchResultsController = true
    }
}

extension SearchEntryViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard case .history = dataSource.itemIdentifier(for: indexPath) else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case let .history(history) = dataSource.itemIdentifier(for: indexPath) else { return }
        resultsController.entrySelected(history.original)
    }
}

extension SearchEntryViewController: Restorable {
    // MARK: - Restorable

    func restore() -> RestorableViewController {
        presentingAlert?.dismiss(animated: false, completion: nil)
        return SearchEntryViewController(state: rootStore.stateValue,
                                         dependency: rootStore.dependency,
                                         thumbnailProcessingQueue: resultsController.thumbnailProcessingQueue,
                                         imageQueryService: resultsController.imageQueryService,
                                         appBundle: appBundle)
    }
}
