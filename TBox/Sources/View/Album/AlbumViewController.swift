//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class AlbumViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = AlbumViewModelType & ClipCollectionViewModelType

    enum Section {
        case main
    }

    private let factory: Factory
    private let viewModel: AlbumViewModelType & ClipCollectionViewModelType
    private let clipCollectionProvider: ClipCollectionProvider
    private let navigationItemsProvider: ClipCollectionNavigationBarProvider
    private let menuBuilder: ClipCollectionMenuBuildable.Type
    private let toolBarItemsProvider: ClipCollectionToolBarProvider
    private let thumbnailStorage: ThumbnailStorageProtocol

    private let emptyMessageView = EmptyMessageView()
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Clip>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var collectionView: ClipsCollectionView!
    private var cancellableBag: Set<AnyCancellable> = .init()

    var selectedClips: [Clip] {
        return self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
    }

    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: AlbumViewModelType & ClipCollectionViewModelType,
         clipCollectionProvider: ClipCollectionProvider,
         navigationItemsProvider: ClipCollectionNavigationBarProvider,
         toolBarItemsProvider: ClipCollectionToolBarProvider,
         menuBuilder: ClipCollectionMenuBuildable.Type,
         thumbnailStorage: ThumbnailStorageProtocol)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.clipCollectionProvider = clipCollectionProvider
        self.navigationItemsProvider = navigationItemsProvider
        self.toolBarItemsProvider = toolBarItemsProvider
        self.menuBuilder = menuBuilder
        self.thumbnailStorage = thumbnailStorage

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

        self.bind(to: viewModel)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.viewModel.inputs.viewDidAppear.send(())
    }

    @IBAction func didTapAlbumView(_ sender: UITapGestureRecognizer) {
        self.navigationItem.titleView?.endEditing(true)
    }

    // MARK: - Methods

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.clips
            .sink { [weak self] clips in
                guard let self = self else { return }

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
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.selections
            .sink { [weak self] selection in
                guard let self = self else { return }

                let indexPaths = selection
                    .compactMap { identity in
                        dependency.outputs.clips.value.first(where: { $0.identity == identity })
                    }
                    .compactMap { self.dataSource.indexPath(for: $0) }
                self.collectionView.applySelection(at: indexPaths)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .sink { [weak self] operation in self?.apply(operation) }
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .map { $0.isEditing }
            .assignNoRetain(to: \.isEditing, on: self)
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .map { $0.isEditing }
            .assign(to: \.hidesBackButton, on: navigationItem)
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .map { $0 == .reordering }
            .assign(to: \.dragInteractionEnabled, on: collectionView)
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .map { $0 == .selecting }
            .assign(to: \.allowsMultipleSelection, on: collectionView)
            .store(in: &self.cancellableBag)

        dependency.outputs.title
            .assignNoRetain(to: \.title, on: self)
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.presentPreview
            .sink { [weak self] clipId, completion in
                guard let self = self else { return }
                guard let viewController = self.factory.makeClipPreviewViewController(clipId: clipId) else {
                    completion(false)
                    return
                }
                completion(true)
                self.present(viewController, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        self.navigationItemsProvider.bind(view: self, viewModel: dependency)
        self.toolBarItemsProvider.bind(view: self, viewModel: dependency)
    }

    private func apply(_ operation: ClipCollection.Operation) {
        switch operation {
        case .reordering:
            self.collectionView.setCollectionViewLayout(self.createGridLayout(), animated: true)

        default:
            let layout = ClipCollectionLayout()
            layout.delegate = self.clipCollectionProvider
            self.collectionView.setCollectionViewLayout(layout, animated: true)
        }
    }

    // MARK: CollectionView

    private func setupCollectionView() {
        self.clipCollectionProvider.delegate = self
        self.clipCollectionProvider.dataSource = self

        let layout = ClipCollectionLayout()
        layout.delegate = self.clipCollectionProvider

        self.collectionView = ClipsCollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.backgroundClient.color
        self.collectionView.delegate = self.clipCollectionProvider
        self.collectionView.contentInsetAdjustmentBehavior = .always

        self.view.addSubview(collectionView)

        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: self.clipCollectionProvider.provideCell(collectionView:indexPath:clip:))

        // Reorder settings

        self.dataSource.reorderingHandlers.canReorderItem = { [weak self] _ in
            guard let self = self else { return false }
            return self.isEditing
        }

        self.dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            guard let clipIds = self.viewModel.outputs.clips.value
                .applying(transaction.difference)?
                .map({ $0.id }) else { return }
            self.viewModel.inputs.reorder.send(clipIds)
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
        self.title = self.viewModel.outputs.album.value?.title
        self.navigationItemsProvider.delegate = self
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

extension AlbumViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var previewingClip: Clip? {
        return self.viewModel.outputs.previewingClip
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

extension AlbumViewController: ClipCollectionProviderDataSource {
    // MARK: - ClipCollectionProviderDataSource

    func isEditing(_ provider: ClipCollectionProvider) -> Bool {
        return self.isEditing
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, clipFor indexPath: IndexPath) -> Clip? {
        return self.dataSource.itemIdentifier(for: indexPath)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, imageFor clipItem: ClipItem) -> UIImage? {
        return self.thumbnailStorage.readThumbnailIfExists(for: clipItem)
    }

    func requestImage(_ provider: ClipCollectionProvider, for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void) {
        self.thumbnailStorage.requestThumbnail(for: clipItem, completion: completion)
    }

    func clipsListCollectionMenuBuilder(_ provider: ClipCollectionProvider) -> ClipCollectionMenuBuildable.Type {
        return self.menuBuilder
    }

    func clipsListCollectionMenuContext(_ provider: ClipCollectionProvider) -> ClipCollection.Context {
        return .init(isAlbum: true)
    }
}

extension AlbumViewController: ClipCollectionProviderDelegate {
    // MARK: - ClipCollectionProviderDelegate

    func clipCollectionProvider(_ provider: ClipCollectionProvider, didSelect clipId: Clip.Identity) {
        self.viewModel.inputs.select.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, didDeselect clipId: Clip.Identity) {
        self.viewModel.inputs.deselect.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddTagsTo clipId: Clip.Identity) {
        guard
            let clip = self.viewModel.outputs.clips.value.first(where: { $0.identity == clipId }),
            let viewController = self.factory.makeTagSelectionViewController(selectedTags: clip.tags.map({ $0.identity }), context: clipId, delegate: self)
        else {
            return
        }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddToAlbum clipId: Clip.Identity) {
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: clipId, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldRemoveFromAlbum clipId: Clip.Identity) {
        self.viewModel.inputs.removeFromAlbum.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldDelete clipId: Clip.Identity) {
        self.viewModel.inputs.delete.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldUnhide clipId: Clip.Identity) {
        self.viewModel.inputs.unhide.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldHide clipId: Clip.Identity) {
        self.viewModel.inputs.hide.send(clipId)
    }
}

extension AlbumViewController: ClipCollectionAlertPresentable {}

extension AlbumViewController: ClipCollectionNavigationBarProviderDelegate {
    // MARK: - ClipCollectionNavigationBarProviderDelegate

    func didTapEditButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operation.send(.selecting)
    }

    func didTapCancelButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operation.send(.none)
    }

    func didTapSelectAllButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.selectAll.send(())
    }

    func didTapDeselectAllButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.deselectAll.send(())
    }

    func didTapReorderButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operation.send(.reordering)
    }

    func didTapDoneButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operation.send(.none)
    }
}

extension AlbumViewController: ClipCollectionToolBarProviderDelegate {
    // MARK: - ClipCollectionToolBarProviderDelegate

    func shouldAddToAlbum(_ provider: ClipCollectionToolBarProvider) {
        guard !self.selectedClips.isEmpty else { return }
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipCollectionToolBarProvider) {
        guard !self.selectedClips.isEmpty else { return }
        guard let viewController = self.factory.makeTagSelectionViewController(selectedTags: [], context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldRemoveFromAlbum(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.removeSelectionsFromAlbum.send(())
    }

    func shouldDelete(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.deleteSelections.send(())
    }

    func shouldHide(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.hideSelections.send(())
    }

    func shouldUnhide(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.unhideSelections.send(())
    }
}

extension AlbumViewController: AlbumSelectionPresenterDelegate {
    // MARK: - AlbumSelectionPresenterDelegate

    func albumSelectionPresenter(_ presenter: AlbumSelectionPresenter, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?) {
        if self.isEditing {
            self.viewModel.inputs.addSelectionsToAlbum.send(albumId)
        } else {
            guard let clipId = context as? Clip.Identity else { return }
            self.viewModel.inputs.addToAlbum.send((albumId, clipId))
        }
    }
}

extension AlbumViewController: TagSelectionPresenterDelegate {
    // MARK: - TagSelectionPresenterDelegate

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagsHaving tagIds: Set<Tag.Identity>, withContext context: Any?) {
        if self.isEditing {
            self.viewModel.inputs.addTagsToSelections.send(tagIds)
        } else {
            guard let clipId = context as? Clip.Identity else { return }
            self.viewModel.inputs.addTags.send((tagIds, clipId))
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

extension AlbumViewController: ClipCollectionViewProtocol {}
