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
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = L10n.placeholderSearchUniversal
        searchController.searchBar.searchTextField.allowsCopyingTokens = true
        searchController.searchBar.searchTextField.allowsDeletingTokens = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true

        // TODO: 初回にメニュー内容が更新されない問題をどうにかする
        let filterButtonItem = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = filterButtonItem
        resultsController.filterButtonItem = filterButtonItem
    }
}

extension SearchEntryViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            self.resultsController.view.isHidden = false
        }
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        resultsController.view.isHidden = false
    }
}
