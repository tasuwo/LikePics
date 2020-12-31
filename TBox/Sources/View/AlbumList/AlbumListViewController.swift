//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class AlbumListViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = AlbumListViewModelType

    enum ElementKind: String {
        case remover
    }

    enum Section {
        case main
    }

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: ViewModel

    private let viewModel: Dependency
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: View

    private let emptyMessageView = EmptyMessageView()
    private lazy var addAlbumAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.albumListViewAlertForAddTitle,
                             message: L10n.albumListViewAlertForAddMessage,
                             placeholder: L10n.albumListViewAlertForAddPlaceholder)
    )
    private lazy var editAlbumTitleAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.albumListViewAlertForEditTitle,
                             message: L10n.albumListViewAlertForEditMessage,
                             placeholder: L10n.albumListViewAlertForEditPlaceholder)
    )
    private var collectionView: AlbumListCollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Album>!

    // MARK: Thumbnail

    private let thumbnailLoader: ThumbnailLoader

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: AlbumListViewModel,
         thumbnailLoader: ThumbnailLoader)
    {
        self.factory = factory
        self.thumbnailLoader = thumbnailLoader
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupNavigationBar()
        self.setupCollectionView()
        self.setupEmptyMessage()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    private func startAddingAlbum() {
        self.addAlbumAlertContainer.present(
            withText: nil,
            on: self,
            validator: {
                $0?.isEmpty != true
            }, completion: { [weak self] action in
                guard case let .saved(text: text) = action else { return }
                self?.viewModel.inputs.addedAlbum.send(text)
            }
        )
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.albums
            .receive(on: DispatchQueue.global())
            .sink { [weak self] albums in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Album>()
                snapshot.appendSections([.main])
                snapshot.appendItems(albums)
                self?.dataSource.apply(snapshot, animatingDifferences: !albums.isEmpty)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.displayEmptyMessage
            .receive(on: DispatchQueue.main)
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)

        dependency.outputs.isEditButtonEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in self?.navigationItem.rightBarButtonItem?.isEnabled = isEnabled }
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView = AlbumListCollectionView(frame: self.view.bounds, collectionViewLayout: self.createLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color
        self.view.addSubview(collectionView)
        self.collectionView.delegate = self
        self.configureDataSource()
    }

    private func configureDataSource() {
        let supplementaryRegistration = UICollectionView.SupplementaryRegistration<AlbumListRemoverView>(elementKind: ElementKind.remover.rawValue) { [weak self] badgeView, _, _ in
            badgeView.delegate = self
            badgeView.isHidden = self?.isEditing == false
        }

        self.dataSource = .init(collectionView: self.collectionView) { [weak self] collectionView, indexPath, album -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumListCollectionView.cellIdentifier, for: indexPath)
            guard let self = self, let cell = dequeuedCell as? AlbumListCollectionViewCell else { return dequeuedCell }

            cell.title = album.title
            cell.clipCount = album.clips.count
            cell.isEditing = self.isEditing
            cell.delegate = self

            let requestId = UUID().uuidString
            cell.identifier = requestId

            if let thumbnailTarget = album.clips.first?.items.first {
                let info = ThumbnailRequest.ThumbnailInfo(id: "album-list-\(thumbnailTarget.identity.uuidString)",
                                                          size: cell.thumbnailSize,
                                                          scale: cell.traitCollection.displayScale)
                let imageRequest = NewImageDataLoadRequest(imageId: thumbnailTarget.imageId)
                let request = ThumbnailRequest(requestId: requestId,
                                               originalImageRequest: imageRequest,
                                               thumbnailInfo: info)
                self.thumbnailLoader.load(request: request, observer: cell)
                cell.onReuse = { [weak self] in self?.thumbnailLoader.cancel(request) }
            } else {
                cell.thumbnail = nil
                cell.onReuse = {}
            }

            return cell
        }

        self.dataSource.supplementaryViewProvider = {
            return self.collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryRegistration, for: $2)
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment -> NSCollectionLayoutSection? in
            let removerAnchor = NSCollectionLayoutAnchor(edges: [.top, .leading], fractionalOffset: CGPoint(x: -0.45, y: -0.45))
            let removerSize = NSCollectionLayoutSize(widthDimension: .absolute(44),
                                                     heightDimension: .absolute(44))
            let remover = NSCollectionLayoutSupplementaryItem(layoutSize: removerSize,
                                                              elementKind: ElementKind.remover.rawValue,
                                                              containerAnchor: removerAnchor)

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize, supplementaryItems: [remover])

            let count: Int = {
                switch environment.traitCollection.horizontalSizeClass {
                case .compact:
                    return 2

                case .regular, .unspecified:
                    return 4

                @unknown default:
                    return 4
                }
            }()
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            group.interItemSpacing = .fixed(16)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = CGFloat(16)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

            return section
        }

        return layout
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.albumListViewTitle
        self.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem?.isEnabled = false
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

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.navigationItem.leftBarButtonItem?.isEnabled = !editing

        let shouldHide = !editing

        let cells = self.collectionView.visibleCells.compactMap { $0 as? AlbumListCollectionViewCell }
        let removers = self.collectionView.visibleSupplementaryViews(ofKind: ElementKind.remover.rawValue)
        removers.forEach { remover in
            remover.isHidden = shouldHide
            remover.alpha = shouldHide ? 1 : 0
        }
        UIView.animate(withDuration: 0.2) {
            removers.forEach { $0.alpha = shouldHide ? 0 : 1 }
            cells.forEach {
                $0.isEditing = editing
                $0.layoutIfNeeded()
            }
        }
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
        guard !self.isEditing else { return }
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

extension AlbumListViewController: AlbumListRemoverViewDelegate {
    // MARK: - AlbumListRemoverViewDelegate

    func albumListRemoverView(_ view: AlbumListRemoverView) {
        guard let indexPath = self.collectionView.indexPath(for: view, ofKind: ElementKind.remover.rawValue),
            let album = self.dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }

        let alert = UIAlertController(title: L10n.albumListViewAlertForDeleteTitle(album.title),
                                      message: L10n.albumListViewAlertForDeleteMessage(album.title),
                                      preferredStyle: .actionSheet)

        let action = UIAlertAction(title: L10n.albumListViewAlertForDeleteAction, style: .destructive) { [weak self] _ in
            self?.viewModel.inputs.deletedAlbum.send(album.id)
        }
        alert.addAction(action)
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.sourceView = view

        self.present(alert, animated: true, completion: nil)
    }
}

extension AlbumListViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        self.startAddingAlbum()
    }
}

extension AlbumListViewController: AlbumListCollectionViewCellDelegate {
    // MARK: - AlbumListCollectionViewCellDelegate

    func didTapTitleEditButton(_ cell: AlbumListCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let album = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.editAlbumTitleAlertContainer.present(
            withText: album.title,
            on: self,
            validator: {
                $0?.isEmpty != true && $0 != album.title
            }, completion: { [weak self] action in
                guard case let .saved(text: text) = action else { return }
                self?.viewModel.inputs.editedAlbumTitle.send((album.id, text))
            }
        )
    }
}
