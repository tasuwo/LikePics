//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class SearchEntryViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = SearchEntryViewModelType

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: View

    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: States

    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: Dependency)
    {
        self.factory = factory
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAppearance()
        setupSearchController()

        bind(to: viewModel)
    }

    // MARK: - Methods

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.displayErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.performSearch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                guard let viewController = self?.factory.makeSearchResultViewController(context: context) else {
                    RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open SearchResultViewController."))
                    return
                }
                self?.show(viewController, sender: nil)
            }
            .store(in: &self.subscriptions)
    }

    // MARK: Preparation

    private func setupAppearance() {
        title = L10n.searchEntryViewTitle
        view.backgroundColor = Asset.Color.backgroundClient.color
    }

    private func setupSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = L10n.placeholderSearchTag
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
}

extension SearchEntryViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let text = self.searchController.searchBar.text ?? ""
        self.viewModel.inputs.queryInputted.send(text)
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.viewModel.inputs.queryInputted.send(searchBar.text ?? "")
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
        viewModel.inputs.queryEntered.send(())
        searchController.searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
    }
}

extension SearchEntryViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let text = self.searchController.searchBar.text ?? ""
        self.viewModel.inputs.queryInputted.send(text)
    }
}
