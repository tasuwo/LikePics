//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Persistence
import Smoothie
import UIKit

class SearchResultViewController: UIViewController {
    typealias Layout = SearchResultViewLayout
    typealias Store = LikePics.Store<SearchResultViewState, SearchResultViewAction, SearchResultViewDependency>

    // MARK: - Properties

    // MARK: View

    lazy var searchController = UISearchController(searchResultsController: self)
    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: Observations

    private var visibilitySubscription: NSKeyValueObservation?

    // MARK: Dependencies

    private let thumbnailLoader: ThumbnailLoaderProtocol

    // MARK: - Initializers

    init(state: SearchResultViewState,
         dependency: SearchResultViewDependency,
         thumbnailLoader: ThumbnailLoaderProtocol)
    {
        self.thumbnailLoader = thumbnailLoader
        self.store = Store(initialState: state, dependency: dependency, reducer: SearchResultViewReducer.self)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .red

        configureViewHierarchy()
        configureDataSource()
        configureSearchController()

        bind(to: store)
    }
}

// MARK: - Bind

extension SearchResultViewController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.global().async {
                self.applySnapshot(for: state)
            }

            let currentTokens = self.searchController.searchBar.searchTextField.tokens.compactMap { $0.underlyingToken }
            let nextTokens = state.searchQuery.tokens
            if currentTokens != nextTokens {
                self.searchController.searchBar.searchTextField.text = ""
                self.searchController.searchBar.searchTextField.tokens = nextTokens.map { $0.uiSearchToken }
            }
        }
        .store(in: &subscriptions)
    }

    private func applySnapshot(for state: SearchResultViewState) {
        var snapshot = Layout.Snapshot()

        snapshot.appendSections([.tokenCandidates])
        snapshot.appendItems(state.tokenCandidates.map { Layout.Item.tokenCandidate($0) })

        snapshot.appendSections([.results])
        snapshot.appendItems(state.searchResults.map({ Layout.Item.result($0) }))

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Configuration

extension SearchResultViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        // swiftlint:disable identifier_name
        let _dataSource = Layout.createDataSource(collectionView: collectionView,
                                                  thumbnailLoader: thumbnailLoader,
                                                  seeAllButtonHandler: { [weak store] in store?.execute(.selectedSeeAllResultsButton) })
        dataSource = _dataSource
        collectionView.delegate = self
    }

    private func configureSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = L10n.placeholderSearchUniversal
        searchController.searchBar.searchTextField.allowsCopyingTokens = true
        searchController.searchBar.searchTextField.allowsDeletingTokens = true
        searchController.searchResultsUpdater = self

        visibilitySubscription = self.view.observe(\.isHidden, options: .new) { [weak searchController] view, change in
            // HACK: 文字列が空の時でも、TextFieldがフォーカスされていればResultsControllerは表示させる
            if change.newValue == true, searchController?.searchBar.searchTextField.isEditing == true {
                view.isHidden = false
            }
        }
    }
}

extension SearchResultViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case let .tokenCandidate(token):
            store.execute(.selectedTokenCandidate(token))

        case let .result(clip):
            store.execute(.selectedResult(clip))
        }
    }
}

extension SearchResultViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(.make(from: searchBar)))
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.store.execute(.searchQueryChanged(.make(from: searchBar)))
            }
        }
        return true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
    }
}

extension SearchResultViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        store.execute(.searchQueryChanged(.make(from: searchController.searchBar)))
    }
}

private extension SearchQuery {
    static func make(from searchBar: UISearchBar) -> Self {
        return .init(tokens: searchBar.searchTextField.tokens.compactMap { $0.underlyingToken },
                     text: searchBar.text ?? "")
    }
}
