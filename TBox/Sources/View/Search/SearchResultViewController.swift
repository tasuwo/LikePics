//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

class SearchResultViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: SearchResultPresenterProtocol
    private let clipsListCollectionViewProvider: ClipsListCollectionViewProvider
    private let navigationItemsProvider: ClipsListNavigationItemsProvider
    private let toolBarItemsProvider: ClipsListToolBarItemsProvider
    private let menuBuilder: ClipCollectionMenuBuildable.Type
    private let emptyMessageView = EmptyMessageView()

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Clip>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    internal var collectionView: ClipsCollectionView!

    var selectedClips: [Clip] {
        return self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
    }

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: SearchResultPresenterProtocol,
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

        self.setupAppearance()
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

    // MARK: - Methods

    private func setupAppearance() {
        self.title = self.presenter.context.title
    }

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
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
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

        switch self.presenter.context {
        case let .keywords(keywords):
            self.emptyMessageView.title = L10n.searchResultForKeywordsEmptyTitle(keywords.joined(separator: " "))

        case let .tag(tag):
            self.emptyMessageView.title = L10n.searchResultForTagEmptyTitle(tag.name)

        case .uncategorized:
            self.emptyMessageView.title = L10n.searchResultForUncategorizedEmptyTitle
        }

        self.emptyMessageView.isMessageHidden = true
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

extension SearchResultViewController: SearchResultViewProtocol {
    // MARK: - SearchResultViewProtocol

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

    func setEditing(_ editing: Bool) {
        self.setEditing(editing, animated: true)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SearchResultViewController: ClipPreviewPresentingViewController {
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

extension SearchResultViewController: ClipsListCollectionViewProviderDataSource {
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
        return .init(isAlbum: false)
    }
}

extension SearchResultViewController: ClipsListCollectionViewProviderDelegate {
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
        // NOP
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

extension SearchResultViewController: ClipsListAlertPresentable {}

extension SearchResultViewController: ClipsListNavigationItemsProviderDelegate {
    // MARK: - ClipsListNavigationItemsProviderDelegate

    func didTapEditButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.setEditing(true)
    }

    func didTapCancelButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.setEditing(false)
    }

    func didTapSelectAllButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.selectAll()
    }

    func didTapDeselectAllButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.deselectAll()
    }

    func didTapReorderButton(_ provider: ClipsListNavigationItemsProvider) {
        // NOP
    }

    func didTapDoneButton(_ provider: ClipsListNavigationItemsProvider) {
        // NOP
    }
}

extension SearchResultViewController: ClipsListToolBarItemsProviderDelegate {
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
        // NOP
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

extension SearchResultViewController: AlbumSelectionPresenterDelegate {
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

extension SearchResultViewController: TagSelectionPresenterDelegate {
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
