//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class SearchResultViewController: UIViewController {
    typealias Layout = SearchResultViewLayout
    typealias Store = LikePics.Store<SearchResultViewState, SearchResultViewAction, SearchResultViewDependency>

    // MARK: - Properties

    // MARK: View

    lazy var searchController = UISearchController(searchResultsController: self)
    private var collectionView: UICollectionView!
    private let notFoundMessageView = NotFoundMessageView()
    private var dataSource: Layout.DataSource!

    weak var filterButtonItem: UIBarButtonItem?

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: Dependencies

    private let filterMenuBuilder = SearchMenuBuilder()
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

        configureViewHierarchy()
        configureDataSource()
        configureSearchController()
        configureNotFoundMessageView()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Event from Entry View

extension SearchResultViewController {
    func entryViewDidAppear(_ animated: Bool) {
        store.execute(.entryViewDidAppear)
    }

    func entrySelected(_ history: Domain.ClipSearchHistory) {
        searchController.searchBar.becomeFirstResponder()
        store.execute(.selectedHistory(history))

        // HACK: searchBarへのテキストの反映を`bind(to:)`内で行うと、更新タイミングによっては
        //       変換中のテキストが意図せず確定されてしまう
        //       searchBarのテキストは基本的にはreadOnlyとし、検索履歴の再現時のみ例外的にこのタイミングで設定を行う
        searchController.searchBar.text = history.query.text
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

            self.notFoundMessageView.message = state.notFoundMessage
            self.notFoundMessageView.alpha = state.isNotFoundMessageDisplaying ? 1 : 0

            self.filterButtonItem?.menu = self.filterMenuBuilder.build(state.menuState,
                                                                       isSomeItemsHiddenByUserSetting: state.isSomeItemsHidden) { [weak self] change in
                self?.store.execute(.displaySettingMenuChanged(change))
            } sortChangeHandler: { [weak self] change in
                self?.store.execute(.sortMenuChanged(change))
            }

            let currentTokens = self.searchController.searchBar.searchTextField.tokens.compactMap { $0.underlyingToken }
            let nextTokens = state.inputtedTokens
            if currentTokens != nextTokens {
                self.searchController.searchBar.searchTextField.text = state.inputtedText
                self.searchController.searchBar.searchTextField.tokens = nextTokens.map { $0.uiSearchToken }
            }
        }
        .store(in: &subscriptions)
    }

    private func applySnapshot(for state: SearchResultViewState) {
        let nextTokenCandidates = state.tokenCandidates.map { Layout.Item.tokenCandidate($0) }
        let nextResults = state.searchResults.map { Layout.Item.result($0) }

        guard dataSource.snapshot().isDifferent(from: state) else { return }

        var snapshot = Layout.Snapshot()

        if !nextTokenCandidates.isEmpty {
            snapshot.appendSections([.tokenCandidates])
            snapshot.appendItems(nextTokenCandidates, toSection: .tokenCandidates)
        }

        if !nextResults.isEmpty {
            snapshot.appendSections([.results])
            snapshot.appendItems(nextResults, toSection: .results)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

private extension SearchResultViewController.Layout.Snapshot {
    func isDifferent(from state: SearchResultViewState) -> Bool {
        let newTokenCandidates = state.tokenCandidates.map { SearchResultViewController.Layout.Item.tokenCandidate($0) }
        let newResults = state.searchResults.map { SearchResultViewController.Layout.Item.result($0) }

        let isDifferentTokenCandidatesFromNew: Bool = {
            if self.sectionIdentifiers.contains(.tokenCandidates) {
                return self.itemIdentifiers(inSection: .tokenCandidates) != newTokenCandidates
            } else {
                return !newTokenCandidates.isEmpty
            }
        }()

        let isDifferentResultsFromNew: Bool = {
            if self.sectionIdentifiers.contains(.results) {
                return self.itemIdentifiers(inSection: .results) != newResults
            } else {
                return !newResults.isEmpty
            }
        }()

        return isDifferentTokenCandidatesFromNew || isDifferentResultsFromNew
    }
}

// MARK: - Configuration

extension SearchResultViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        let provider: () -> Layout.DataSource? = { [weak self] in return self?.dataSource }
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout(provider))
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))

        notFoundMessageView.alpha = 0
        view.addSubview(notFoundMessageView)
        notFoundMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(notFoundMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))
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
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
    }

    private func configureNotFoundMessageView() {
        notFoundMessageView.title = L10n.searchResultNotFoundTitle
        notFoundMessageView.message = ""
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
            self.executeSearchBarChangeEvent(searchBar)
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.executeSearchBarChangeEvent(searchBar)
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
        executeSearchBarChangeEvent(searchController.searchBar)
    }
}

extension SearchResultViewController {
    func executeSearchBarChangeEvent(_ searchBar: UISearchBar) {
        store.execute(.searchBarChanged(text: searchBar.text ?? "",
                                        tokens: searchBar.searchTextField.tokens.compactMap { $0.underlyingToken }))
    }
}

extension SearchResultViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var previewingClip: Clip? {
        store.stateValue.previewingClip
    }

    var previewingCell: ClipPreviewPresentingCell? {
        guard let clip = previewingClip, let indexPath = dataSource.indexPath(for: .result(clip)) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? SearchResultClipCell
    }

    var previewingCellCornerRadius: CGFloat {
        return SearchResultClipCell.imageCornerRadius
    }

    func displayOnScreenPreviewingCellIfNeeded(shouldAdjust: Bool) {
        guard let clip = previewingClip, let indexPath = dataSource.indexPath(for: .result(clip)) else { return }

        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()

        if shouldAdjust {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            view.layoutIfNeeded()
            collectionView.layoutIfNeeded()
        }
    }
}
