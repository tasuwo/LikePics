//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class SearchResultViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = SearchResultViewModelType & ClipCollectionViewModelType

    enum Section {
        case main
    }

    private let factory: Factory
    private let viewModel: SearchResultViewModelType & ClipCollectionViewModelType
    private let clipCollectionProvider: ClipCollectionProvider
    private let navigationItemsProvider: ClipCollectionNavigationBarProvider
    private let toolBarItemsProvider: ClipCollectionToolBarProvider
    private let menuBuilder: ClipCollectionMenuBuildable.Type
    private let thumbnailStorage: ThumbnailStorageProtocol

    private let emptyMessageView = EmptyMessageView()
    private var dataSource: UICollectionViewDiffableDataSource<Section, Clip>!
    internal var collectionView: ClipCollectionView!
    private var cancellableBag: Set<AnyCancellable> = .init()

    var selectedClips: [Clip] {
        return self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
    }

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: SearchResultViewModelType & ClipCollectionViewModelType,
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

    // MARK: - Methods

    // MARK: Bind

    func bind(to dependency: Dependency) {
        dependency.outputs.clips
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clips in
                guard let self = self else { return }

                var snapshot = NSDiffableDataSourceSnapshot<Section, Clip>()
                snapshot.appendSections([.main])
                snapshot.appendItems(clips)

                if !clips.isEmpty {
                    self.emptyMessageView.alpha = 0
                }
                self.dataSource.apply(snapshot, animatingDifferences: true) {
                    guard clips.isEmpty else { return }
                    UIView.animate(withDuration: 0.2) {
                        self.emptyMessageView.alpha = 1
                    }
                }
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.selections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selection in
                guard let self = self else { return }

                let indexPaths = selection
                    .compactMap { identity in
                        self.viewModel.outputs.clips.value.first(where: { $0.identity == identity })
                    }
                    .compactMap { self.dataSource.indexPath(for: $0) }
                self.collectionView.applySelection(at: indexPaths)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .receive(on: DispatchQueue.main)
            .map { $0.isEditing }
            .assignNoRetain(to: \.isEditing, on: self)
            .store(in: &self.cancellableBag)

        dependency.outputs.title
            .receive(on: DispatchQueue.main)
            .map { $0 as String? }
            .assignNoRetain(to: \.title, on: self)
            .store(in: &self.cancellableBag)

        dependency.outputs.emptyMessage
            .receive(on: DispatchQueue.main)
            .map { $0 as String? }
            .assign(to: \.title, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.presentPreview
            .receive(on: DispatchQueue.main)
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

    // MARK: CollectionView

    private func setupCollectionView() {
        self.clipCollectionProvider.delegate = self
        self.clipCollectionProvider.dataSource = self

        let layout = ClipCollectionLayout()
        layout.delegate = self.clipCollectionProvider

        self.collectionView = ClipCollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color
        self.collectionView.delegate = self.clipCollectionProvider
        self.collectionView.contentInsetAdjustmentBehavior = .always

        self.view.addSubview(collectionView)

        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: self.clipCollectionProvider.provideCell(collectionView:indexPath:clip:))
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
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
        NSLayoutConstraint.activate(self.emptyMessageView.constraints(fittingIn: self.view.safeAreaLayoutGuide))

        self.emptyMessageView.isMessageHidden = true
        self.emptyMessageView.isActionButtonHidden = true

        self.emptyMessageView.alpha = 0
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.collectionView.allowsMultipleSelection = editing
    }
}

extension SearchResultViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var previewingClip: Clip? {
        return self.viewModel.outputs.previewingClip
    }

    var previewingCell: ClipCollectionViewCell? {
        guard
            let clip = self.previewingClip,
            let indexPath = self.dataSource.indexPath(for: clip)
        else {
            return nil
        }
        return self.collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell
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

extension SearchResultViewController: ClipCollectionProviderDataSource {
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
        return .init(isAlbum: false)
    }
}

extension SearchResultViewController: ClipCollectionProviderDelegate {
    // MARK: - ClipCollectionProviderDelegate

    func clipCollectionProvider(_ provider: ClipCollectionProvider, didSelect clipId: Clip.Identity) {
        self.viewModel.inputs.select.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, didDeselect clipId: Clip.Identity) {
        self.viewModel.inputs.deselect.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddTagsTo clipId: Clip.Identity, at indexPath: IndexPath) {
        guard
            let clip = self.viewModel.outputs.clips.value.first(where: { $0.identity == clipId }),
            let viewController = self.factory.makeTagSelectionViewController(selectedTags: clip.tags.map({ $0.identity }), context: clipId, delegate: self)
        else {
            return
        }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddToAlbum clipId: Clip.Identity, at indexPath: IndexPath) {
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: clipId, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldRemoveFromAlbum clipId: Clip.Identity, at indexPath: IndexPath) {
        // NOP
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldDelete clipId: Clip.Identity, at indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) else {
            RootLogger.shared.write(ConsoleLog(level: .info, message: "Failed to delete clip. Target cell not found"))
            return
        }
        self.presentDeleteAlert(at: cell, in: self.collectionView) { [weak self] in
            guard let self = self else { return }
            self.viewModel.inputs.delete.send(clipId)
        }
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldUnhide clipId: Clip.Identity, at indexPath: IndexPath) {
        self.viewModel.inputs.unhide.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldHide clipId: Clip.Identity, at indexPath: IndexPath) {
        self.viewModel.inputs.hide.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldShare clipId: Clip.Identity, at indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) else { return }
        let images = self.viewModel.outputs.fetchImages(for: clipId)
        let controller = UIActivityViewController(activityItems: images, applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = self.collectionView
        controller.popoverPresentationController?.sourceRect = cell.frame
        controller.completionWithItemsHandler = { _, _, _, _ in
            self.viewModel.operation.send(.none)
        }
        self.present(controller, animated: true, completion: nil)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldPurge clipId: Clip.Identity, at indexPath: IndexPath) {
        self.viewModel.inputs.purge.send(clipId)
    }
}

extension SearchResultViewController: ClipCollectionAlertPresentable {}

extension SearchResultViewController: ClipCollectionNavigationBarProviderDelegate {
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
        // NOP
    }

    func didTapDoneButton(_ provider: ClipCollectionNavigationBarProvider) {
        // NOP
    }
}

extension SearchResultViewController: ClipCollectionToolBarProviderDelegate {
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
        // NOP
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

    func shouldCancel(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.operation.send(.none)
    }

    func present(_ provider: ClipCollectionToolBarProvider, controller: UIActivityViewController) {
        self.present(controller, animated: true, completion: nil)
    }

    func fetchImages(_ provider: ClipCollectionToolBarProvider) -> [Data] {
        return self.viewModel.outputs.fetchImagesForSelectedClips()
    }
}

extension SearchResultViewController: AlbumSelectionPresenterDelegate {
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

extension SearchResultViewController: TagSelectionPresenterDelegate {
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

extension SearchResultViewController: ClipCollectionViewProtocol {}
