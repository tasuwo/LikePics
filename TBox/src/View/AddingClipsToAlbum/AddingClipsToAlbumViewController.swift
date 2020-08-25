//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class AddingClipsToAlbumViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: AddingClipsToAlbumPresenter

    @IBOutlet var tableView: UITableView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AddingClipsToAlbumPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupTableView()
        self.setupNavigationBar()

        self.presenter.reload()
    }

    // MARK: - Methods

    private func setupTableView() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    private func setupNavigationBar() {
        self.navigationItem.title = "アルバムに追加"
    }
}

extension AddingClipsToAlbumViewController: AddingClipsToAlbumViewProtocol {
    // MARK: - AddingClipsToAlbumViewProtocol

    func startLoading() {
        // TODO:
    }

    func endLoading() {
        // TODO:
    }

    func showErrorMassage(_ message: String) {
        // TODO:
        print(message)
    }

    func reload() {
        self.tableView.reloadData()
    }

    func closeView(completion: @escaping () -> Void) {
        self.dismiss(animated: true, completion: completion)
    }
}

extension AddingClipsToAlbumViewController: UITableViewDelegate {
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.presenter.clipTo(albumAt: indexPath.row)
    }
}

extension AddingClipsToAlbumViewController: UITableViewDataSource {
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.presenter.albums.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell") else {
            return UITableViewCell()
        }
        guard self.presenter.albums.indices.contains(indexPath.row) else { return cell }

        cell.textLabel?.text = self.presenter.albums[indexPath.row].title

        return cell
    }
}
