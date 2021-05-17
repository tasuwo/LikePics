//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import UIKit

class SearchEntryViewController: UIViewController {
    typealias RootStore = LikePics.Store<SearchViewRootState, SearchViewRootAction, SearchViewRootDependency>

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

    // MARK: - Initializers

    init(rootStore: RootStore,
         store: Store,
         searchResultViewController: SearchResultViewController)
    {
        self.rootStore = rootStore
        self.store = store
        resultsController = searchResultViewController

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resultsController.entryViewDidAppear(animated)
        updateUserActivity(rootStore.stateValue)
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

// MARK: - Bind

extension SearchEntryViewController {
    private func bind(to store: RootStore) {
        store.state
            .receive(on: DispatchQueue.global())
            .removeDuplicates()
            .debounce(for: 3, scheduler: DispatchQueue.global())
            .sink { [weak self] state in self?.updateUserActivity(state) }
            .store(in: &subscriptions)
    }

    private func updateUserActivity(_ state: SearchViewRootState) {
        DispatchQueue.global().async {
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(Intent.seeSearch(state.removingSessionStates())),
                  let string = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self.view.window?.windowScene?.userActivity = NSUserActivity.make(with: string)
            }
        }
    }
}

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
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
            .store(in: &subscriptions)
    }

    private func applySnapshot(searchHistories: [ClipSearchHistory], isSomeItemsHidden: Bool) {
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
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension SearchEntryViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

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
