//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class TopClipCollectionViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: TopClipCollectionPresenterProtocol
    private let clipCollectionProvider: ClipCollectionProvider
    private let navigationItemsProvider: ClipCollectionNavigationBarProvider
    private let toolBarItemsProvider: ClipCollectionToolBarProvider
    private let menuBuilder: ClipCollectionMenuBuildable.Type

    private let emptyMessageView = EmptyMessageView()

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Clip>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    internal var collectionView: ClipsCollectionView!
    private var cancellableBag: Set<AnyCancellable> = .init()

    var selectedClips: [Clip] {
        return self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
    }

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: TopClipCollectionPresenterProtocol,
         clipCollectionProvider: ClipCollectionProvider,
         navigationItemsProvider: ClipCollectionNavigationBarProvider,
         toolBarItemsProvider: ClipCollectionToolBarProvider,
         menuBuilder: ClipCollectionMenuBuildable.Type)
    {
        self.factory = factory
        self.presenter = presenter
        self.clipCollectionProvider = clipCollectionProvider
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

        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupToolBar()
        self.setupEmptyMessage()

        self.presenter.setup(with: self)

        self.bind(to: self.presenter)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.presenter.viewDidAppear()
    }

    // MARK: - Methods

    // MARK: Bind

    private func bind(to presenter: TopClipCollectionPresenterProtocol) {
        self.presenter.clips
            .sink { _ in } receiveValue: { [weak self] clips in self?.apply(clips) }
            .store(in: &self.cancellableBag)

        self.presenter.selections
            .sink { _ in } receiveValue: { [weak self] selection in self?.apply(selection: selection) }
            .store(in: &self.cancellableBag)
    }

    private func apply(_ clips: [Clip]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Clip>()
        snapshot.appendSections([.main])
        snapshot.appendItems(clips)

        if !clips.isEmpty {
            self.emptyMessageView.alpha = 0
        }
        self.dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard clips.isEmpty else { return }
            self?.emptyMessageView.alpha = 1
        }

        self.navigationItemsProvider.onUpdateSelection()
    }

    private func apply(selection: Set<Clip.Identity>) {
        let indexPaths = selection
            .compactMap { [weak self] identity in
                self?.presenter.clips.value.first(where: { $0.identity == identity })
            }
            .compactMap { self.dataSource.indexPath(for: $0) }
        self.collectionView.applySelection(at: indexPaths)

        self.navigationItemsProvider.onUpdateSelection()
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
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
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

        self.emptyMessageView.title = L10n.topClipViewEmptyTitle
        self.emptyMessageView.message = L10n.topClipViewEmptyMessage
        self.emptyMessageView.isActionButtonHidden = true

        self.emptyMessageView.alpha = 0
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.collectionView.allowsMultipleSelection = editing
        self.toolBarItemsProvider.setEditing(editing, animated: animated)
        self.navigationItemsProvider.set(editing ? .selecting : .default)
    }
}

extension TopClipCollectionViewController: TopClipCollectionViewProtocol {
    // MARK: - TopClipCollectionViewProtocol

    func presentPreview(forClipId clipId: Clip.Identity, availability: @escaping (_ isAvailable: Bool) -> Void) {
        guard let viewController = self.factory.makeClipPreviewViewController(clipId: clipId) else {
            availability(false)
            return
        }
        availability(true)
        self.present(viewController, animated: true, completion: nil)
    }

    func setEditing(_ editing: Bool) {
        self.setEditing(editing, animated: true)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension TopClipCollectionViewController: ClipPreviewPresentingViewController {
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

extension TopClipCollectionViewController: ClipCollectionProviderDataSource {
    // MARK: - ClipCollectionProviderDataSource

    func isEditing(_ provider: ClipCollectionProvider) -> Bool {
        return self.isEditing
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, clipFor indexPath: IndexPath) -> Clip? {
        return self.dataSource.itemIdentifier(for: indexPath)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, imageFor clipItem: ClipItem) -> UIImage? {
        return self.presenter.readImageIfExists(for: clipItem)
    }

    func requestImage(_ provider: ClipCollectionProvider, for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void) {
        self.presenter.fetchImage(for: clipItem, completion: completion)
    }

    func clipsListCollectionMenuBuilder(_ provider: ClipCollectionProvider) -> ClipCollectionMenuBuildable.Type {
        return self.menuBuilder
    }

    func clipsListCollectionMenuContext(_ provider: ClipCollectionProvider) -> ClipCollection.Context {
        return .init(isAlbum: false)
    }
}

extension TopClipCollectionViewController: ClipCollectionProviderDelegate {
    // MARK: - ClipCollectionProviderDelegate

    func clipCollectionProvider(_ provider: ClipCollectionProvider, didSelect clipId: Clip.Identity) {
        self.presenter.select(clipId: clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, didDeselect clipId: Clip.Identity) {
        self.presenter.deselect(clipId: clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddTagsTo clipId: Clip.Identity) {
        guard
            let clip = self.presenter.clips.value.first(where: { $0.identity == clipId }),
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
        // NOP
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldDelete clipId: Clip.Identity) {
        self.presenter.deleteClip(having: clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldUnhide clipId: Clip.Identity) {
        self.presenter.unhideClip(having: clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldHide clipId: Clip.Identity) {
        self.presenter.hideClip(having: clipId)
    }
}

extension TopClipCollectionViewController: ClipCollectionAlertPresentable {}

extension TopClipCollectionViewController: ClipCollectionNavigationBarProviderDelegate {
    // MARK: - ClipCollectionNavigationBarProviderDelegate

    func didTapEditButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.presenter.setEditing(true)
    }

    func didTapCancelButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.presenter.setEditing(false)
    }

    func didTapSelectAllButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.presenter.selectAll()
    }

    func didTapDeselectAllButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.presenter.deselectAll()
    }

    func didTapReorderButton(_ provider: ClipCollectionNavigationBarProvider) {
        // NOP
    }

    func didTapDoneButton(_ provider: ClipCollectionNavigationBarProvider) {
        // NOP
    }
}

extension TopClipCollectionViewController: ClipCollectionToolBarProviderDelegate {
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
        self.presenter.deleteSelectedClips()
    }

    func shouldHide(_ provider: ClipCollectionToolBarProvider) {
        self.presenter.hideSelectedClips()
    }

    func shouldUnhide(_ provider: ClipCollectionToolBarProvider) {
        self.presenter.unhideSelectedClips()
    }
}

extension TopClipCollectionViewController: AlbumSelectionPresenterDelegate {
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

extension TopClipCollectionViewController: TagSelectionPresenterDelegate {
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
