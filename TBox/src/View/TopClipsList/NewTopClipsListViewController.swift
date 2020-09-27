//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class NewTopClipsListViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: NewTopClipsListPresenterProtocol
    private let navigationItemsProvider: ClipsListNavigationItemsProvider
    private let toolBarItemsProvider: ClipsListToolBarItemsProvider

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
         presenter: NewTopClipsListPresenterProtocol,
         navigationItemsProvider: ClipsListNavigationItemsProvider,
         toolBarItemsProvider: ClipsListToolBarItemsProvider)
    {
        self.factory = factory
        self.presenter = presenter
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

    // MARK: - Methods

    // MARK: CollectionView

    private func setupCollectionView() {
        let layout = ClipCollectionLayout()
        layout.delegate = self

        self.collectionView = ClipsCollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.backgroundClient.color
        self.collectionView.delegate = self

        self.view.addSubview(collectionView)

        self.configureDataSouce()
    }

    private func configureDataSouce() {
        self.dataSource = .init(collectionView: self.collectionView) { [weak self] collectionView, indexPath, clip -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipsCollectionView.cellIdentifier, for: indexPath)
            guard let cell = dequeuedCell as? ClipsCollectionViewCell else { return dequeuedCell }

            cell.primaryImage = {
                guard let data = self?.presenter.getImageData(for: .primary, in: clip) else { return nil }
                return UIImage(data: data)
            }()
            cell.secondaryImage = {
                guard let data = self?.presenter.getImageData(for: .secondary, in: clip) else { return nil }
                return UIImage(data: data)
            }()
            cell.tertiaryImage = {
                guard let data = self?.presenter.getImageData(for: .tertiary, in: clip) else { return nil }
                return UIImage(data: data)
            }()

            cell.visibleSelectedMark = self?.isEditing ?? false

            return cell
        }
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

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.collectionView.setEditing(editing, animated: animated)
        self.navigationItemsProvider.setEditing(editing, animated: animated)
        self.toolBarItemsProvider.setEditing(editing, animated: animated)
    }
}

extension NewTopClipsListViewController: NewTopClipsListViewProtocol {
    // MARK: - NewTopClipsListViewProtocol

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

    func presentPreview(for clip: Clip) {
        let nextViewController = self.factory.makeClipPreviewViewController(clip: clip)
        self.present(nextViewController, animated: true, completion: nil)
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

extension NewTopClipsListViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var selectedIndexPath: IndexPath? {
        return self.collectionView.indexPathsForSelectedItems?.first
    }

    var clips: [Clip] {
        return self.presenter.clips
    }
}

extension NewTopClipsListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clip = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.presenter.select(clipId: clip.identity)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let clip = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.presenter.deselect(clipId: clip.identity)
    }
}

extension NewTopClipsListViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard let clip = self.dataSource.itemIdentifier(for: indexPath) else { return .zero }

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))

        case let (.some(item), .some, .none):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin

        case let (.some(item), .some, .some):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin
                + ClipsCollectionViewCell.tertiaryStickingOutMargin

        case let (.some(item), _, _):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))

        default:
            return width
        }
    }
}

extension NewTopClipsListViewController: ClipsListAlertPresentable {}

extension NewTopClipsListViewController: ClipsListNavigationItemsProviderDelegate {
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

extension NewTopClipsListViewController: ClipsListToolBarItemsProviderDelegate {
    // MARK: - ClipsListToolBarItemsProviderDelegate

    func shouldAddToAlbum(_ provider: ClipsListToolBarItemsProvider) {
        guard !self.selectedClips.isEmpty else { return }
        let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: self.selectedClips, delegate: nil)
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipsListToolBarItemsProvider) {
        guard !self.selectedClips.isEmpty else { return }
        let viewController = self.factory.makeAddingTagToClipViewController(clips: self.selectedClips, delegate: nil)
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
