//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class SearchEntryViewController: UIViewController {
    // MARK: - Properties

    // MARK: View

    private let resultsController: SearchResultViewController
    private var searchController: UISearchController { resultsController.searchController }

    // MARK: - Initializers

    init(searchResultViewController: SearchResultViewController) {
        resultsController = searchResultViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.searchEntryViewTitle

        configureViewHierarchy()
        configureSearchController()
    }
}

// MARK: - Configuration

extension SearchEntryViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color
    }

    private func configureSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = L10n.placeholderSearchUniversal
        searchController.searchBar.searchTextField.allowsCopyingTokens = true
        searchController.searchBar.searchTextField.allowsDeletingTokens = true
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
}

extension SearchEntryViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            // TODO:
            print(searchBar.text ?? "nil")
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                // TODO:
                print(searchBar.text ?? "nil")
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

extension SearchEntryViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        // TODO:
        print(searchController.searchBar.text ?? "nil")
    }
}
