//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import Smoothie
import UIKit

class SearchResultViewController: UIViewController {
    typealias Layout = SearchResultViewLayout
    typealias Store = AnyStoring<SearchResultViewState, SearchResultViewAction, SearchResultViewDependency>

    // MARK: - Properties

    // MARK: View

    lazy var searchController = UISearchController(searchResultsController: self)
    private var collectionView: UICollectionView!
    private let notFoundMessageView = NotFoundMessageView()
    private var dataSource: Layout.DataSource!

    var filterButtonItem: UIBarButtonItem!

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private let collectionUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.SearchResultViewController")

    // MARK: Service

    let thumbnailProcessingQueue: ImageProcessingQueue
    let imageQueryService: ImageQueryServiceProtocol
    private let filterMenuBuilder = SearchMenuBuilder()

    // MARK: - Initializers

    init(store: Store,
         thumbnailProcessingQueue: ImageProcessingQueue,
         imageQueryService: ImageQueryServiceProtocol)
    {
        self.store = store
        self.thumbnailProcessingQueue = thumbnailProcessingQueue
        self.imageQueryService = imageQueryService

        super.init(nibName: nil, bundle: nil)
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
        store.state
            .removeDuplicates(by: { $0.tokenCandidates == $1.tokenCandidates && $0.searchResults == $1.searchResults })
            .receive(on: collectionUpdateQueue)
            .sink { [weak self] state in
                self?.applySnapshot(tokenCandidates: state.tokenCandidates, searchResults: state.searchResults)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.notFoundMessage, to: \.message, on: notFoundMessageView)
            .store(in: &subscriptions)
        store.state
            .bind(\.notFoundMessageViewAlpha, to: \.alpha, on: notFoundMessageView)
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: { $0.menuState == $1.menuState && $0.isSomeItemsHidden == $1.isSomeItemsHidden })
            .sink { [weak self] state in
                guard let self = self else { return }
                self.filterButtonItem.menu = self.filterMenuBuilder.build(state.menuState, isSomeItemsHiddenByUserSetting: state.isSomeItemsHidden) { change in
                    self.store.execute(.displaySettingMenuChanged(change))
                } sortChangeHandler: { change in
                    self.store.execute(.sortMenuChanged(change))
                }
            }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.inputtedTokens)
            .sink { [weak self] state in
                guard let self = self else { return }
                let currentTokens = self.searchController.searchBar.searchTextField.tokens.compactMap { $0.underlyingToken }
                let nextTokens = state.inputtedTokens
                if currentTokens != nextTokens {
                    // textを先に更新すると `UISearchResultsUpdating` のメソッドが呼び出されて無限ループしてしまうので、
                    // トークンを先に更新する
                    self.searchController.searchBar.searchTextField.tokens = nextTokens.map { $0.uiSearchToken }
                    self.searchController.searchBar.searchTextField.text = state.inputtedText
                }
            }
            .store(in: &subscriptions)
    }

    // MARK: Snapshot

    private func applySnapshot(tokenCandidates: [ClipSearchToken], searchResults: [Clip]) {
        let nextTokenCandidates = tokenCandidates.map { Layout.Item.tokenCandidate($0) }
        let nextResults = searchResults.map { Layout.Item.result($0) }

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

// MARK: - Configuration

extension SearchResultViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

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
        let _dataSource = Layout.createDataSource(collectionView, thumbnailProcessingQueue, imageQueryService) { [weak store] in
            store?.execute(.selectedSeeAllResultsButton)
        }
        dataSource = _dataSource
        collectionView.delegate = self
    }

    private func configureSearchController() {
        // イベント発火を避けるためにdelegate設定前にリストアする必要がある
        searchController.searchBar.text = store.stateValue.inputtedText
        searchController.searchBar.searchTextField.tokens = store.stateValue.inputtedTokens.map { $0.uiSearchToken }

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

    var previewingCellCornerRadius: CGFloat {
        return SearchResultClipCell.imageCornerRadius
    }

    var previewingCollectionView: UICollectionView {
        collectionView
    }

    func previewingCell(id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool) -> ClipPreviewPresentableCell? {
        guard let clip = store.stateValue.searchedClips?.results.first(where: { $0.id == id.clipId }),
              let indexPath = dataSource.indexPath(for: .result(clip)) else { return nil }

        if needsScroll {
            // セルが画面外だとインスタンスを取り出せないので、表示する
            displayPreviewingCell(id: id)
        }

        return collectionView.cellForItem(at: indexPath) as? SearchResultClipCell
    }

    func displayPreviewingCell(id: ClipPreviewPresentableCellIdentifier) {
        guard let clip = store.stateValue.searchedClips?.results.first(where: { $0.id == id.clipId }),
              let indexPath = dataSource.indexPath(for: .result(clip)) else { return }

        // collectionViewのみでなくviewも再描画しないとセルの座標系がおかしくなる
        // また、scrollToItem呼び出し前に一度再描画しておかないと、正常にスクロールができないケースがある
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)

        // スクロール後に再描画しないと、セルの座標系が更新されない
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
    }

    var isDisplayablePrimaryThumbnailOnly: Bool { true }
}
