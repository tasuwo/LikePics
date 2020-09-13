//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class AlbumListViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: AlbumListPresenter
    private lazy var alertContainer = AddingAlert(configuration: .init(title: L10n.albumListViewAlertForAddTitle,
                                                                       message: L10n.albumListViewAlertForAddMessage,
                                                                       placeholder: L10n.albumListViewAlertForAddPlaceholder),
                                                  baseView: self)

    @IBOutlet var collectionView: AlbumListCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AlbumListPresenter) {
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

        self.setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.presenter.reload()
    }

    // MARK: - Methods

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.albumListViewTitle
        self.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))

        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @objc
    func didTapAdd() {
        self.alertContainer.present { [weak self] action in
            switch action {
            case let .saved(text: text):
                self?.presenter.addAlbum(title: text)

            default:
                // NOP
                break
            }
        }
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.collectionView.visibleCells
            .compactMap { $0 as? AlbumListCollectionViewCell }
            .forEach { $0.visibleDeleteButton = editing }
    }
}

extension AlbumListViewController: AlbumListViewProtocol {
    // MARK: - AlbumListViewProtocol

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func reload() {
        self.collectionView.reloadData()
    }
}

extension AlbumListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.presenter.albums.indices.contains(indexPath.row) else { return }
        let album = self.presenter.albums[indexPath.row]
        let viewController = self.factory.makeAlbumViewController(album: album)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AlbumListViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.albums.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumListCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? AlbumListCollectionViewCell else { return dequeuedCell }
        guard self.presenter.albums.indices.contains(indexPath.row) else { return cell }

        let album = self.presenter.albums[indexPath.row]
        cell.title = album.title

        if let data = self.presenter.getThumbnailImageData(at: indexPath.row), let image = UIImage(data: data) {
            cell.thumbnail = image
        } else {
            cell.thumbnail = nil
        }

        cell.deletate = self
        cell.visibleDeleteButton = self.isEditing

        return cell
    }
}

extension AlbumListViewController: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: AlbumListCollectionViewCell.preferredWidth,
                      height: AlbumListCollectionViewCell.preferredHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 16, bottom: 16, right: 16)
    }
}

extension AlbumListViewController: AlbumListCollectionViewCellDelegate {
    // MARK: - AlbumListCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: AlbumListCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
        let target = self.presenter.albums[indexPath.row]

        let alert = UIAlertController(title: L10n.albumListViewAlertForDeleteTitle(target.title),
                                      message: L10n.albumListViewAlertForDeleteMessage(target.title),
                                      preferredStyle: .actionSheet)

        let action = UIAlertAction(title: L10n.albumListViewAlertForDeleteAction, style: .destructive) { [weak self] _ in
            self?.presenter.deleteAlbum(at: indexPath.row)
        }
        alert.addAction(action)
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}
