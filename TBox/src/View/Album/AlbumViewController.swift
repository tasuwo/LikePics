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
    private let toolBarItemsProvider: ClipsListToolBarItemsProvider

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Clip>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    internal var collectionView: ClipsCollectionView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    var selectedClips: [Clip] {
        return self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
    }

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: AlbumPresenterProtocol,
         clipsListCollectionViewProvider: ClipsListCollectionViewProvider,
         navigationItemsProvider: ClipsListNavigationItemsProvider,
         toolBarItemsProvider: ClipsListToolBarItemsProvider)
    {
        self.factory = factory
        self.presenter = presenter
        self.clipsListCollectionViewProvider = clipsListCollectionViewProvider
        self.navigationItemsProvider = navigationItemsProvider
        self.toolBarItemsProvider = toolBarItemsProvider

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

        self.view.addSubview(collectionView)

        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: self.clipsListCollectionViewProvider.provideCell(collectionView:indexPath:clip:))
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

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.collectionView.setEditing(editing, animated: animated)
        self.navigationItemsProvider.setEditing(editing, animated: animated)
        self.toolBarItemsProvider.setEditing(editing, animated: animated)
    }
}

extension AlbumViewController: AlbumViewProtocol {
    // MARK: - AlbumViewProtocol

    func apply(_ clips: [Clip]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Clip>()
        snapshot.appendSections([.main])
        snapshot.appendItems(clips)
        self.dataSource.apply(snapshot)

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

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, imageDataAt layer: ThumbnailLayer, in clip: Clip) -> Data? {
        return self.presenter.getImageData(for: layer, in: clip)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, clipFor indexPath: IndexPath) -> Clip? {
        return self.dataSource.itemIdentifier(for: indexPath)
    }
}

extension AlbumViewController: ClipsListCollectionViewProviderDelegate {
    // MARK: - ClipsListCollectionViewProviderDelegate

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didSelectClip clipId: Clip.Identity) {
        self.presenter.select(clipId: clipId)
    }

    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didDeselectClip clipId: Clip.Identity) {
        self.presenter.deselect(clipId: clipId)
    }
}

extension AlbumViewController: ClipsListAlertPresentable {}

extension AlbumViewController: ClipsListNavigationItemsProviderDelegate {
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
}

extension AlbumViewController: ClipsListToolBarItemsProviderDelegate {
    // MARK: - ClipsListToolBarItemsProviderDelegate

    func shouldAddToAlbum(_ provider: ClipsListToolBarItemsProvider) {
        guard !self.selectedClips.isEmpty else { return }
        let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: self.selectedClips, delegate: nil)
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipsListToolBarItemsProvider) {
        guard !self.selectedClips.isEmpty else { return }
        guard let viewController = self.factory.makeTagSelectionViewController(selectedTags: [], delegate: self) else { return }
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

extension AlbumViewController: TagSelectionPresenterDelegate {
    // MARK: - TagSelectionPresenterDelegate

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagIds tagIds: Set<Tag.Identity>) {
        self.presenter.addTagsToSelectedClips(tagIds)
    }
}
