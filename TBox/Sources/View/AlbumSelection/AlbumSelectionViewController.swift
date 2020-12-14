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
    private let emptyMessageView = EmptyMessageView()
    private lazy var alertContainer = TextEditAlert(
        configuration: .init(title: L10n.albumListViewAlertForAddTitle,
                             message: L10n.albumListViewAlertForAddMessage,
                             placeholder: L10n.albumListViewAlertForAddPlaceholder)
    )

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UITableViewDiffableDataSource<Section, Album>!

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var tableView: AlbumSelectionTableView!

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
        self.setupEmptyMessage()

        self.presenter.setup()
    }

    // MARK: - Methods

    private func startAddingAlbum() {
        self.alertContainer.present(
            withText: nil,
            on: self,
            validator: {
                $0?.isEmpty != true
            }, completion: { [weak self] action in
                guard case let .saved(text: text) = action else { return }
                self?.presenter.addAlbum(title: text)
            }
        )
    }

    // MARK: Table View

    private func setupTableView() {
        self.tableView = AlbumSelectionTableView(frame: self.view.bounds, style: .plain)
        self.tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tableView.backgroundColor = Asset.Color.backgroundClient.color
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.configureDataSource()
    }

    private func configureDataSource() {
        self.dataSource = .init(tableView: self.tableView) { [weak self] tableView, indexPath, album in
            let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: AlbumSelectionTableView.cellIdentifier, for: indexPath)
            guard let cell = dequeuedCell as? AlbumSelectionCell else { return dequeuedCell }

            cell.identifier = album.identity
            cell.title = album.title

            if let image = self?.presenter.readImageIfExists(for: album) {
                cell.thumbnail = image
            } else {
                cell.thumbnail = nil
                self?.presenter.fetchImage(for: album) { image in
                    DispatchQueue.main.async {
                        guard cell.identifier == album.identity else { return }
                        cell.thumbnail = image
                    }
                }
            }

            return cell
        }
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.albumSelectionViewTitle
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                target: self,
                                                                action: #selector(self.didTapAdd))
    }

    @objc
    func didTapAdd() {
        self.startAddingAlbum()
    }

    // MARK: EmptyMessage

    private func setupEmptyMessage() {
        self.view.addSubview(self.emptyMessageView)
        self.emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(self.emptyMessageView.constraints(fittingIn: self.view.safeAreaLayoutGuide))

        self.emptyMessageView.title = L10n.albumListViewEmptyTitle
        self.emptyMessageView.message = L10n.albumListViewEmptyMessage
        self.emptyMessageView.actionButtonTitle = L10n.albumListViewEmptyActionTitle
        self.emptyMessageView.delegate = self

        self.emptyMessageView.alpha = 0
    }
}

extension AlbumSelectionViewController: AlbumSelectionViewProtocol {
    // MARK: - AlbumSelectionViewProtocol

    func apply(_ albums: [Album]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Album>()
        snapshot.appendSections([.main])
        snapshot.appendItems(albums)

        if !albums.isEmpty {
            self.emptyMessageView.alpha = 0
        }
        self.dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard albums.isEmpty else { return }
            UIView.animate(withDuration: 0.2) {
                self?.emptyMessageView.alpha = 1
            }
        }
    }

    func reload() {
        self.tableView.reloadData()
    }

    func showErrorMessage(_ message: String) {
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

extension AlbumSelectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        self.startAddingAlbum()
    }
}
