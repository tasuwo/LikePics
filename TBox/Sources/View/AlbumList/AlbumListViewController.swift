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
    typealias Layout = AlbumListViewLayout

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: ViewModel

    private let viewModel: Dependency

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
    private var dataSource: Layout.DataSource!

    // MARK: Components

    private let navigationBarProvider: AlbumListNavigationBarProvider
    private let menuBuilder: AlbumListMenuBuildable.Type

    // MARK: Thumbnail

    private let thumbnailLoader: ThumbnailLoader

    // MARK: States

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: AlbumListViewModel,
         navigationBarProvider: AlbumListNavigationBarProvider,
         menuBuilder: AlbumListMenuBuildable.Type,
         thumbnailLoader: ThumbnailLoader)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.navigationBarProvider = navigationBarProvider
        self.menuBuilder = menuBuilder
        self.thumbnailLoader = thumbnailLoader
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

    private func startEditingAlbumTitle(for album: Album) {
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

    private func startDeletingAlbum(_ album: Album) {
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

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        // Dependency Outputs

        dependency.outputs.albums
            .receive(on: DispatchQueue.main)
            .sink { [weak self] albums in
                guard let self = self else { return }
                Layout.apply(items: albums.map { Layout.Item(album: $0) },
                             to: self.dataSource,
                             in: self.collectionView)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .receive(on: DispatchQueue.main)
            .map { $0.isEditing }
            .assignNoRetain(to: \.isEditing, on: self)
            .store(in: &self.cancellableBag)

        dependency.outputs.displayEmptyMessage
            .receive(on: DispatchQueue.main)
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.dragInteractionEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.dragInteractionEnabled, on: self.collectionView)
            .store(in: &self.cancellableBag)

        // Navigation Bar

        self.navigationBarProvider.bind(view: self, propagator: dependency.outputs)

        self.navigationBarProvider.didTapAdd
            .sink { [weak self] _ in self?.startAddingAlbum() }
            .store(in: &self.cancellableBag)

        self.navigationBarProvider.didTapEdit
            .sink { _ in dependency.inputs.operation.send(.editing) }
            .store(in: &self.cancellableBag)

        self.navigationBarProvider.didTapDone
            .sink { _ in dependency.inputs.operation.send(.none) }
            .store(in: &self.cancellableBag)
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView = AlbumListCollectionView(frame: self.view.bounds,
                                                      collectionViewLayout: Layout.createLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color
        self.view.addSubview(collectionView)
        self.collectionView.delegate = self

        self.dataSource = Layout.configureDataSource(collectionView: collectionView,
                                                     thumbnailLoader: thumbnailLoader,
                                                     editing: self,
                                                     delegate: self)

        // Reorder Settings

        self.dataSource.reorderingHandlers.canReorderItem = { [weak self] _ in
            guard let self = self else { return false }
            return self.isEditing
        }

        self.dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            let albumIds = transaction.finalSnapshot.itemIdentifiers.map { $0.album.id }
            self?.viewModel.inputs.reorderedAlbums.send(albumIds)
        }

        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.albumListViewTitle
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

        self.collectionView.visibleCells.compactMap { $0 as? AlbumListCollectionViewCell }
            .forEach { $0.setEditing(editing, animated: true) }
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
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        guard let viewController = self.factory.makeAlbumViewController(albumId: item.album.identity) else {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open AlbumViewController"))
            return
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AlbumListViewController {
    // MARK: - UICollectionViewDelegate (Context Menu)

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = self.dataSource.itemIdentifier(for: indexPath), self.isEditing == false else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil,
                                          actionProvider: self.makeActionProvider(for: item.album, at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration, collectionView: UICollectionView) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? NSIndexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: identifier as IndexPath) else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = UIBezierPath()
        return UITargetedPreview(view: cell, parameters: parameters)
    }

    private func makeActionProvider(for album: Album, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        let items = self.menuBuilder.build(for: album).map {
            self.makeAction(from: $0, for: album, at: indexPath)
        }
        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeAction(from item: AlbumList.MenuItem, for album: Album, at indexPath: IndexPath) -> UIAction {
        switch item {
        case .hide:
            return UIAction(title: L10n.albumListViewContextMenuActionHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.viewModel.inputs.hidedAlbum.send(album.id)
                }
            }

        case .reveal:
            return UIAction(title: L10n.albumListViewContextMenuActionReveal,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.viewModel.inputs.revealedAlbum.send(album.id)
                }
            }

        case .rename:
            return UIAction(title: L10n.albumListViewContextMenuActionUpdate,
                            image: UIImage(systemName: "text.cursor")) { [weak self] _ in
                self?.startEditingAlbumTitle(for: album)
            }

        case .delete:
            return UIAction(title: L10n.albumListViewContextMenuActionDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.startDeletingAlbum(album)
            }
        }
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
            let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.startEditingAlbumTitle(for: item.album)
    }

    func didTapRemover(_ cell: AlbumListCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.startDeletingAlbum(item.album)
    }
}

extension AlbumListViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return [] }
        let provider = NSItemProvider(object: item.album.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumListCollectionViewCell else { return nil }
        return self.makePreviewParameter(for: cell)
    }
}

extension AlbumListViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return self.isEditing
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        // NOP
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AlbumListCollectionViewCell else { return nil }
        return self.makePreviewParameter(for: cell)
    }
}

extension AlbumListViewController {
    // MARK: Drag & Drop

    func makePreviewParameter(for cell: AlbumListCollectionViewCell) -> UIDragPreviewParameters {
        let parameters = UIDragPreviewParameters()
        // HACK: 左上のRemoverアイコンが見切れてしまうため、描画範囲を広げる
        let path: UIBezierPath = {
            let path = UIBezierPath()
            path.move(to: .init(x: -22, y: -22))
            path.addLine(to: .init(x: cell.frame.width, y: 0))
            path.addLine(to: .init(x: cell.frame.width, y: cell.frame.height))
            path.addLine(to: .init(x: -22, y: cell.frame.height))
            path.close()
            return path
        }()
        parameters.visiblePath = path
        parameters.backgroundColor = .clear
        // HACK: nilだとデフォルトの影が描画されてしまうため、空の BezierPath を指定する
        parameters.shadowPath = UIBezierPath()
        return parameters
    }
}

extension AlbumListViewController: AlbumListViewEditing {
    // MARK: - AlbumListViewEditing

    func isEditing(_ layout: AlbumListViewLayout.Type) -> Bool {
        return self.isEditing
    }
}
