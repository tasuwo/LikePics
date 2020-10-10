//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

class AlbumListViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: AlbumListPresenter
    private lazy var alertContainer = TextEditAlert(
        configuration: .init(title: L10n.albumListViewAlertForAddTitle,
                             message: L10n.albumListViewAlertForAddMessage,
                             placeholder: L10n.albumListViewAlertForAddPlaceholder)
    )
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Album>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var collectionView: AlbumListCollectionView!

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
        self.setupCollectionView()

        self.presenter.setup()
    }

    // MARK: - Methods

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView = AlbumListCollectionView(frame: self.view.bounds, collectionViewLayout: self.createLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.backgroundClient.color
        self.view.addSubview(collectionView)
        self.collectionView.delegate = self
        self.configureDataSouce()
    }

    private func configureDataSouce() {
        self.dataSource = .init(collectionView: self.collectionView) { collectionView, indexPath, album -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumListCollectionView.cellIdentifier, for: indexPath)
            guard let cell = dequeuedCell as? AlbumListCollectionViewCell else { return dequeuedCell }

            cell.title = album.title

            if let data = self.presenter.readThumbnailImageData(for: album), let image = UIImage(data: data) {
                cell.thumbnail = image
            } else {
                cell.thumbnail = nil
            }

            cell.deletate = self
            cell.visibleDeleteButton = self.isEditing

            return cell
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment -> NSCollectionLayoutSection? in
            let itemWidth: NSCollectionLayoutDimension = {
                switch environment.traitCollection.horizontalSizeClass {
                case .compact:
                    return .fractionalWidth(0.5)

                case .regular, .unspecified:
                    return .fractionalWidth(0.33)

                @unknown default:
                    return .fractionalWidth(0.33)
                }
            }()
            let itemSize = NSCollectionLayoutSize(widthDimension: itemWidth,
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalWidth(itemWidth.dimension * 4 / 3))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            return section
        }

        return layout
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.albumListViewTitle
        self.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))

        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @objc
    func didTapAdd() {
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

    func apply(_ albums: [Album]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Album>()
        snapshot.appendSections([.main])
        snapshot.appendItems(albums)
        self.dataSource.apply(snapshot)
    }

    func reload() {
        self.collectionView.reloadData()
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
        guard let album = self.dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        guard let viewController = self.factory.makeAlbumViewController(albumId: album.identity) else {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open AlbumViewController"))
            return
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AlbumListViewController: AlbumListCollectionViewCellDelegate {
    // MARK: - AlbumListCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: AlbumListCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let album = self.dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        let alert = UIAlertController(title: L10n.albumListViewAlertForDeleteTitle(album.title),
                                      message: L10n.albumListViewAlertForDeleteMessage(album.title),
                                      preferredStyle: .actionSheet)

        let action = UIAlertAction(title: L10n.albumListViewAlertForDeleteAction, style: .destructive) { [weak self] _ in
            self?.presenter.deleteAlbum(album)
        }
        alert.addAction(action)
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}
