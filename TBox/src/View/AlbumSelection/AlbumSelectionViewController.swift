//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class AlbumSelectionViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: AlbumSelectionPresenter

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UITableViewDiffableDataSource<Section, Album>!

    @IBOutlet var tableView: UITableView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AlbumSelectionPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupTableView()
        self.setupNavigationBar()

        self.presenter.setup()
    }

    // MARK: - Methods

    // MARK: Table View

    private func setupTableView() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.configureDataSource()
    }

    private func configureDataSource() {
        self.dataSource = .init(tableView: self.tableView) { tableView, indexPath, album in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = album.title
            return cell
        }
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.albumSelectionViewTitle
    }
}

extension AlbumSelectionViewController: AlbumSelectionViewProtocol {
    // MARK: - AlbumSelectionViewProtocol

    func apply(_ albums: [Album]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Album>()
        snapshot.appendSections([.main])
        snapshot.appendItems(albums)
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AlbumSelectionViewController: UITableViewDelegate {
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let album = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.presenter.select(albumId: album.id)
    }
}
