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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAppearance()
        self.setupNavigationBar()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.title = L10n.searchEntryViewTitle
        self.view.backgroundColor = Asset.backgroundClient.color
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationItem.searchController = self.makeSearchController()
    }

    private func makeSearchController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = L10n.searchEntryViewSearchBarPlaceholder
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.delegate = self
        searchController.delegate = self
        return searchController
    }
}

extension SearchEntryViewController: SearchEntryViewProtocol {
    // MARK: - SearchEntryViewProtocol

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func showReuslt(_ clips: [Clip], withContext context: SearchContext) {
        self.show(self.factory.makeSearchResultViewController(context: context, clips: clips), sender: nil)
    }
}

extension SearchEntryViewController: UISearchControllerDelegate {
    // MARK: - UISearchControllerDelegate
}

extension SearchEntryViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        self.presenter.search(by: text)
    }
}
