//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class AlbumListViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: AlbumListPresenter

    @IBOutlet var collectionView: AlbumListCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AlbumListPresenter) {
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

        self.setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.presenter.reload()
    }

    // MARK: - Methods

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "アルバム"
        self.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
    }

    @objc func didTapAdd() {
        let alert = AddingAlbumAlertContainer.shared.makeAlert { [weak self] title in
            self?.presenter.addAlbum(title: title)
        }
        self.present(alert, animated: true, completion: nil)
    }
}

extension AlbumListViewController: AlbumListViewProtocol {
    // MARK: - AlbumListViewProtocol

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
        }

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
