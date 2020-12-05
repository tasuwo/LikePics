//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

class AlbumViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: AlbumPresenterProtocol
    private let clipsListCollectionViewProvider: ClipsListCollectionViewProvider
    private let navigationItemsProvider: ClipsListNavigationItemsProvider
    private let menuBuilder: ClipCollectionMenuBuildable.Type
    private let toolBarItemsProvider: ClipsListToolBarItemsProvider
    private let emptyMessageView = EmptyMessageView()

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Clip>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var collectionView: ClipsCollectionView!

    var selectedClips: [Clip] {
        return self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
    }

    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: AlbumPresenterProtocol,
         clipsListCollectionViewProvider: ClipsListCollectionViewProvider,
         navigationItemsProvider: ClipsListNavigationItemsProvider,
         toolBarItemsProvider: ClipsListToolBarItemsProvider,
         menuBuilder: ClipCollectionMenuBuildable.Type)
    {
        self.factory = factory
        self.presenter = presenter
        self.clipsListCollectionViewProvider = clipsListCollectionViewProvider
        self.navigationItemsProvider = navigationItemsProvider
        self.toolBarItemsProvider = toolBarItemsProvider
        self.menuBuilder = menuBuilder

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // HACK: nibから読み込んでいるため初期サイズがnibに引きずられる
        //       これによりCollectionViewのレイアウトが初回表示時にズレるのを防ぐ
        self.view.frame = self.navigationController?.view.frame ?? self.view.frame

        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupToolBar()
        self.setupEmptyMessage()

        self.presenter.setup(with: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.presenter.viewDidAppear()
    }

    @IBAction func didTapAlbumView(_ sender: UITapGestureRecognizer) {
        self.navigationItem.titleView?.endEditing(true)
    }

    // MARK: - Methods

    // MARK: CollectionView

    private func setupCollectionView() {
        self.clipsListCollectionViewProvider.delegate = self
        self.clipsListCollectionViewProvider.dataSource = self

        let layout = ClipCollectionLayout()
        layout.delegate = self.clipsListCollectionViewProvider

        self.collectionView = ClipsCollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.backgroundClient.color
        self.collectionView.delegate = self.clipsListCollectionViewProvider
        self.collectionView.contentInsetAdjustmentBehavior = .always

        self.view.addSubview(collectionView)

        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: self.clipsListCollectionViewProvider.provideCell(collectionView:indexPath:clip:))

        // Reorder settings

        self.dataSource.reorderingHandlers.canReorderItem = { [weak self] _ in
            guard let self = self else { return false }
            return self.isEditing
        }

        self.dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            guard let clipIds = self.presenter.clips.applying(transaction.difference)?.map({ $0.id }) else { return }
            self.presenter.reorderClips(clipIds)
        }

        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
    }

    private func createGridLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment -> NSCollectionLayoutSection? in
            let itemWidth: NSCollectionLayoutDimension = {
                switch environment.traitCollection.horizontalSizeClass {
                case .compact:
                    return .fractionalWidth(0.5)

                case .regular, .unspecified:
                    return .fractionalWidth(0.25)

                @unknown default:
                    return .fractionalWidth(0.25)
                }
            }()
            let itemSize = NSCollectionLayoutSize(widthDimension: itemWidth,
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalWidth(itemWidth.dimension))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            return section
        }

        return layout
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.title = self.presenter.album.title
        self.navigationItemsProvider.delegate = self
        self.navigationItemsProvider.navigationItem = self.navigationItem
    }

    // MARK: ToolBar

    private func setupToolBar() {
        self.toolBarItemsProvider.alertPresentable = self
        self.toolBarItemsProvider.delegate = self
    }

    // MARK: EmptyMessage

    private func setupEmptyMessage() {
        self.view.addSubview(self.emptyMessageView)
        self.emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        self.emptyMessageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.emptyMessageView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.emptyMessageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.emptyMessageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true

        self.emptyMessageView.title = L10n.albumViewEmptyTitle
        self.emptyMessageView.isMessageHidden = true
        self.emptyMessageView.isActionButtonHidden = true

        self.emptyMessageView.alpha = 0
    }
}

extension AlbumViewController: AlbumViewProtocol {
    // MARK: - AlbumViewProtocol

    func apply(_ clips: [Clip]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Clip>()
        snapshot.appendSections([.main])
        snapshot.appendItems(clips)

        if !clips.isEmpty {
            self.emptyMessageView.alpha = 0
        }
        self.dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard clips.isEmpty else { return }
            UIView.animate(withDuration: 0.2) {
                self?.emptyMessageView.alpha = 1
            }
        }

        self.navigationItemsProvider.onUpdateSelection()
    }

    func apply(_ state: AlbumPresenter.State) {
        self.setEditing(state.isEditing, animated: true)

        self.navigationItemsProvider.set(state.map(to: ClipsListNavigationItemsPresenter.State.self))
        self.toolBarItemsProvider.setEditing(state == .selecting, animated: true)
        self.navigationItem.hidesBackButton = state.isEditing

        self.collectionView.dragInteractionEnabled = state == .reordering
        self.collectionView.allowsMultipleSelection = state == .selecting
        switch state {
        case .reordering:
            self.collectionView.setCollectionViewLayout(self.createGridLayout(), animated: true)

        default:
            let layout = ClipCollectionLayout()
            layout.delegate = self.clipsListCollectionViewProvider
            self.collectionView.setCollectionViewLayout(layout, animated: true)
        }
    }

    func apply(selection: Set<Clip>) {
        let indexPaths = selection
            .compactMap { self.dataSource.indexPath(for: $0) }
        self.collectionView.applySelection(at: indexPaths)

        self.navigationItemsProvider.onUpdateSelection()
    }

    func presentPreview(forClipId clipId: Clip.Identity, availability: @escaping (_ isSucceeded: Bool) -> Void) {
        guard let viewController = self.factory.makeClipPreviewViewController(clipId: clipId) else {
            availability(false)
            return
        }
        availability(true)
        self.present(viewController, animated: true, completion: nil)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension AlbumViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var previewingClip: Clip? {
        return self.presenter.previewingClip
    }

    var previewingCell: ClipsCollectionViewCell? {
        guard
            let clip = self.previewingClip,
            let indexPath = self.dataSource.indexPath(for: clip)
        else {
            return nil
        }
        return self.collectionView.cellForItem(at: indexPath) as? ClipsCollectionViewCell
    }

    func displayOnScreenPreviewingCellIfNeeded() {
        guard
            let clip = self.previewingClip,
            let indexPath = self.dataSource.indexPath(for: clip)
        else {
            return
        }

        self.view.layoutIfNeeded()
        self.collectionView.layoutIfNeeded()

        if !self.collectionView.indexPathsForVisibleItems.contains(indexPath) {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            self.view.layoutIfNeeded()
            self.collectionView.layoutIfNeeded()
        }
    }
}

extension AlbumViewController: ClipsListCollectionViewProviderDataSource {
    // MARK: - ClipsListCollectionViewProviderDataSource

    func isEditing(_ provider: ClipsListCollectionViewProvider) -> Bool {
        return self.isEditing
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, clipFor indexPath: IndexPath) -> Clip? {
        return self.dataSource.itemIdentifier(for: indexPath)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, imageFor clipItem: ClipItem) -> UIImage? {
        return self.presenter.readImageIfExists(for: clipItem)
    }

    func requestImage(_ provider: ClipsListCollectionViewProvider, for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void) {
        self.presenter.fetchImage(for: clipItem, completion: completion)
    }

    func clipsListCollectionMenuBuilder(_ provider: ClipsListCollectionViewProvider) -> ClipCollectionMenuBuildable.Type {
        return self.menuBuilder
    }

    func clipsListCollectionMenuContext(_ provider: ClipsListCollectionViewProvider) -> ClipCollection.Context {
        return .init(isAlbum: true)
    }
}

extension AlbumViewController: ClipsListCollectionViewProviderDelegate {
    // MARK: - ClipsListCollectionViewProviderDelegate

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didSelect clipId: Clip.Identity) {
        self.presenter.select(clipId: clipId)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didDeselect clipId: Clip.Identity) {
        self.presenter.deselect(clipId: clipId)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldAddTagsTo clipId: Clip.Identity) {
        guard
            let clip = self.presenter.clips.first(where: { $0.identity == clipId }),
            let viewController = self.factory.makeTagSelectionViewController(selectedTags: clip.tags.map({ $0.identity }), context: clipId, delegate: self)
        else {
            return
        }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldAddToAlbum clipId: Clip.Identity) {
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: clipId, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldRemoveFromAlbum clipId: Clip.Identity) {
        self.presenter.removeFromAlbum(clipHaving: clipId)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldDelete clipId: Clip.Identity) {
        self.presenter.deleteClip(having: clipId)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldUnhide clipId: Clip.Identity) {
        self.presenter.unhideClip(having: clipId)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldHide clipId: Clip.Identity) {
        self.presenter.hideClip(having: clipId)
    }
}

extension AlbumViewController: ClipsListAlertPresentable {}

extension AlbumViewController: ClipsListNavigationItemsProviderDelegate {
    // MARK: - ClipsListNavigationItemsProviderDelegate

    func didTapEditButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.startEditing()
    }

    func didTapCancelButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.cancel()
    }

    func didTapSelectAllButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.selectAll()
    }

    func didTapDeselectAllButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.deselectAll()
    }

    func didTapReorderButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.startReordering()
    }

    func didTapDoneButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.cancel()
    }
}

extension AlbumViewController: ClipsListToolBarItemsProviderDelegate {
    // MARK: - ClipsListToolBarItemsProviderDelegate

    func shouldAddToAlbum(_ provider: ClipsListToolBarItemsProvider) {
        guard !self.selectedClips.isEmpty else { return }
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipsListToolBarItemsProvider) {
        guard !self.selectedClips.isEmpty else { return }
        guard let viewController = self.factory.makeTagSelectionViewController(selectedTags: [], context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldRemoveFromAlbum(_ provider: ClipsListToolBarItemsProvider) {
        self.presenter.removeSelectedClipsFromAlbum()
    }

    func shouldDelete(_ provider: ClipsListToolBarItemsProvider) {
        self.presenter.deleteSelectedClips()
    }

    func shouldHide(_ provider: ClipsListToolBarItemsProvider) {
        self.presenter.hideSelectedClips()
    }

    func shouldUnhide(_ provider: ClipsListToolBarItemsProvider) {
        self.presenter.unhideSelectedClips()
    }
}

extension AlbumViewController: AlbumSelectionPresenterDelegate {
    // MARK: - AlbumSelectionPresenterDelegate

    func albumSelectionPresenter(_ presenter: AlbumSelectionPresenter, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?) {
        if self.isEditing {
            self.presenter.addSelectedClipsToAlbum(albumId)
        } else {
            guard let clipId = context as? Clip.Identity else { return }
            self.presenter.addClip(having: clipId, toAlbumHaving: albumId)
        }
    }
}

extension AlbumViewController: TagSelectionPresenterDelegate {
    // MARK: - TagSelectionPresenterDelegate

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagsHaving tagIds: Set<Tag.Identity>, withContext context: Any?) {
        if self.isEditing {
            self.presenter.addTagsToSelectedClips(tagIds)
        } else {
            guard let clipId = context as? Clip.Identity else { return }
            self.presenter.addTags(having: tagIds, toClipHaving: clipId)
        }
    }
}

extension AlbumViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return [] }
        let provider = NSItemProvider(object: item.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        return [dragItem]
    }
}

extension AlbumViewController: UICollectionViewDropDelegate {
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
}

private extension AlbumPresenter.State {
    func map(to: ClipsListNavigationItemsPresenter.State.Type) -> ClipsListNavigationItemsPresenter.State {
        switch self {
        case .default:
            return .default

        case .reordering:
            return .reordering

        case .selecting:
            return .selecting
        }
    }
}
