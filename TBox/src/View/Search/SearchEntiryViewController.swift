//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class SearchEntryViewController: UIViewController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "検索"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.searchController = self.setupSearchController()

        self.view.backgroundColor = UIColor(named: "background_client")
    }

    // MARK: - Methods

    private func setupSearchController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "クリップを検索する"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.delegate = self
        searchController.delegate = self
        return searchController
    }
}

extension SearchEntryViewController: UISearchControllerDelegate {
    // MARK: - UISearchControllerDelegate
}

extension SearchEntryViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print(#function)
    }
}
