//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class SearchEntryViewController: UIViewController {
    typealias Layout = SearchEntryViewLayout
    typealias Store = LikePics.Store<SearchEntryViewState, SearchEntryViewAction, SearchEntryViewDependency>

    // MARK: - Properties

    // MARK: View

    let resultsController: SearchResultViewController
    private var searchController: UISearchController { resultsController.searchController }
    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: SearchEntryViewState,
         dependency: SearchEntryViewDependency,
         searchResultViewController: SearchResultViewController)
    {
        resultsController = searchResultViewController
        self.store = Store(initialState: state, dependency: dependency, reducer: SearchEntryViewReducer.self)

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
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.searchEntryViewTitle

        configureViewHierarchy()
        configureDataSource()
        configureSearchController()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension SearchEntryViewController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.global().async {
                self.applySnapshot(for: state)
            }
        }
        .store(in: &subscriptions)
    }

    private func applySnapshot(for state: SearchEntryViewState) {
        var snapshot = Layout.Snapshot()

        snapshot.appendSections([.main])

        if state.searchHistories.isEmpty {
            snapshot.appendItems([.empty], toSection: .main)
        } else {
            snapshot.appendItems(state.searchHistories.map { Layout.Item.history($0) }, toSection: .main)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
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
                self.store.execute(.removedHistory(history, completion: completion))
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
        let _dataSource = Layout.createDataSource(collectionView: collectionView)
        dataSource = _dataSource
        collectionView.delegate = self
    }

    private func configureSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = false

        searchController.searchBar.placeholder = L10n.placeholderSearchUniversal
        searchController.searchBar.searchTextField.allowsCopyingTokens = true
        searchController.searchBar.searchTextField.allowsDeletingTokens = true

        definesPresentationContext = true

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true

        let filterButtonItem = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"),
                                               style: .plain,
                                               target: nil,
                                               action: nil)
        navigationItem.rightBarButtonItem = filterButtonItem
        resultsController.filterButtonItem = filterButtonItem

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
        resultsController.entrySelected(history)
    }
}
