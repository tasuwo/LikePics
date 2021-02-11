//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import TBoxUIKit
import UIKit

class NewTagCollectionViewController: UIViewController {
    typealias Layout = TagCollectionViewLayout

    // MARK: - Properties

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private let emptyMessageView = EmptyMessageView()
    private let searchController = UISearchController(searchResultsController: nil)

    private var store: TagCollectionViewStore
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(dependency: TagCollectionViewStore.Reducer.Dependency,
         state: TagCollectionViewStore.Reducer.State,
         observe: (TagCollectionViewStore, inout Set<AnyCancellable>) -> Void)
    {
        self.store = TagCollectionViewStore(dependency: dependency, state: state)
        super.init(nibName: nil, bundle: nil)
        observe(store, &subscriptions)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.tagListViewTitle

        configureViewHierarchy()
        configureDataSource()
        configureNavigationBar()
        configureSearchController()
        configureEmptyMessageView()

        bind(to: store)
    }
}

// MARK: - Bind

extension NewTagCollectionViewController {
    private func bind(to store: TagCollectionViewStore) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            // 初回表示時にCollectionViewの表示位置がズレることがあるため、
            // バックグラウンドスレッドで余裕を持って更新させる
            DispatchQueue.global().async {
                Layout.apply(items: state.items, to: self.dataSource, in: self.collectionView)
            }

            self.collectionView.isHidden = !state.isCollectionViewDisplaying

            self.emptyMessageView.alpha = state.isEmptyMessageViewDisplaying ? 1 : 0

            self.searchController.set(isEnabled: state.isSearchBarEnabled)
            self.searchController.set(text: state.searchQuery)

            if let message = state.errorMessageAlert {
                self.presentErrorMessageAlertIfNeeded(message: message)
            }
        }
        .store(in: &subscriptions)
    }

    private func presentErrorMessageAlertIfNeeded(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.errorAlertDismissed)
        })
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension NewTagCollectionViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))

        emptyMessageView.alpha = 0
        view.addSubview(self.emptyMessageView)
        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        dataSource = Layout.configureDataSource(collectionView: collectionView,
                                                uncategorizedCellDelegate: self)
    }

    private func configureNavigationBar() {
        let addItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            self?.store.execute(.tagAdditionButtonTapped)
        })
        self.navigationItem.leftBarButtonItem = addItem
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
        self.emptyMessageView.title = L10n.tagListViewEmptyTitle
        self.emptyMessageView.message = L10n.tagListViewEmptyMessage
        self.emptyMessageView.actionButtonTitle = L10n.tagListViewEmptyActionTitle
        self.emptyMessageView.delegate = self
    }
}

extension NewTagCollectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch self.dataSource.itemIdentifier(for: indexPath) {
        case let .tag(listingTag):
            store.execute(.select(listingTag.tag))

        default: () // NOP
        }
    }
}

extension NewTagCollectionViewController: UISearchBarDelegate {
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

extension NewTagCollectionViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        store.execute(.searchQueryChanged(searchController.searchBar.text ?? ""))
    }
}

extension NewTagCollectionViewController: UncategorizedCellDelegate {
    // MARK: - UncategorizedCellDelegate

    func didTap(_ cell: UncategorizedCell) {
        store.execute(.uncategorizedTagButtonTapped)
    }
}

extension NewTagCollectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}
