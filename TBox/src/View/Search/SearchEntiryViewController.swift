//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class SearchEntryViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: SearchEntryPresenter
    private let transitionController: ClipPreviewTransitionControllerProtocol

    // MARK: - Lifecycle

    init(factory: Factory, presenter: SearchEntryPresenter, transitionController: ClipPreviewTransitionControllerProtocol) {
        self.factory = factory
        self.presenter = presenter
        self.transitionController = transitionController
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "検索"
        self.navigationItem.searchController = self.setupSearchController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.prefersLargeTitles = true
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

extension SearchEntryViewController: SearchEntryViewProtocol {
    // MARK: - SearchEntryViewProtocol

    func startLoading() {
        // TODO:
    }

    func endLoading() {
        // TODO:
    }

    func showErrorMassage(_ message: String) {
        print(message)
    }

    func showReuslt(_ clips: [Clip]) {
        self.show(self.factory.makeSearchResultViewController(clips: clips), sender: nil)
    }
}

extension SearchEntryViewController: UISearchControllerDelegate {
    // MARK: - UISearchControllerDelegate
}

extension SearchEntryViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        self.presenter.search(text.split(separator: " ").map { String($0) })
    }
}
