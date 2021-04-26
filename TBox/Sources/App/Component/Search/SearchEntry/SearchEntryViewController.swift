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
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
}
