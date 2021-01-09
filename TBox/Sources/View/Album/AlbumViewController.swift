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
    typealias Dependency = AlbumViewModelType

    enum Section {
        case main
    }

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: ViewModel

    private let viewModel: Dependency

    // MARK: Provider

    private let clipCollectionProvider: ClipCollectionProvider
    private let navigationItemsProvider: ClipCollectionNavigationBarProvider
    private let toolBarItemsProvider: ClipCollectionToolBarProvider
    private let menuBuilder: ClipCollectionMenuBuildable.Type

    // MARK: View

    private let emptyMessageView = EmptyMessageView()
    private var dataSource: UICollectionViewDiffableDataSource<Section, Clip>!
    var collectionView: ClipCollectionView!
    private var cancellableBag: Set<AnyCancellable> = .init()

    var selectedClips: [Clip] {
        return self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
    }

    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: Dependency,
         clipCollectionProvider: ClipCollectionProvider,
         navigationItemsProvider: ClipCollectionNavigationBarProvider,
         toolBarItemsProvider: ClipCollectionToolBarProvider,
         menuBuilder: ClipCollectionMenuBuildable.Type)
    {
        self.factory = factory
        self.viewModel = viewModel
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

    // swiftlint:disable:next function_body_length
    private func bind(to dependency: Dependency) {
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
                self.dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                    self?.updateHiddenIconAppearance()

                    guard clips.isEmpty else { return }
                    UIView.animate(withDuration: 0.2) {
                        self?.emptyMessageView.alpha = 1
                    }
                }
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.selected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selected in
                guard let self = self else { return }
                selected
                    .compactMap { self.dataSource.indexPath(for: $0) }
                    .forEach { self.collectionView.selectItem(at: $0, animated: false, scrollPosition: []) }
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.deselected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deselected in
                guard let self = self else { return }
                deselected
                    .compactMap { self.dataSource.indexPath(for: $0) }
                    .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] operation in self?.apply(operation) }
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .receive(on: DispatchQueue.main)
            .map { $0.isEditing }
            .assignNoRetain(to: \.isEditing, on: self)
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .receive(on: DispatchQueue.main)
            .map { $0.isEditing }
            .assign(to: \.hidesBackButton, on: navigationItem)
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .receive(on: DispatchQueue.main)
            .map { $0 == .reordering }
            .assign(to: \.dragInteractionEnabled, on: collectionView)
            .store(in: &self.cancellableBag)

        dependency.outputs.operation
            .receive(on: DispatchQueue.main)
            .map { $0 == .selecting }
            .assign(to: \.allowsMultipleSelection, on: collectionView)
            .store(in: &self.cancellableBag)

        dependency.outputs.title
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assignNoRetain(to: \.title, on: self)
            .store(in: &self.cancellableBag)

        dependency.outputs.displayErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.previewed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clipId in
                guard let viewController = self?.factory.makeClipPreviewViewController(clipId: clipId) else {
                    self?.viewModel.inputs.previewCancelled.send(())
                    return
                }
                self?.present(viewController, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.startMerging
            .receive(on: DispatchQueue.main)
            .sink { [weak self] clips in
                guard let self = self else { return }
                let viewController = self.factory.makeMergeViewController(clips: clips, delegate: self)
                self.present(viewController, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.startSharing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                guard case let .menu(clip) = context.source,
                    let self = self,
                    let indexPath = self.dataSource.indexPath(for: clip),
                    let cell = self.collectionView.cellForItem(at: indexPath)
                else {
                    return
                }
                let controller = UIActivityViewController(activityItems: context.data, applicationActivities: nil)
                controller.popoverPresentationController?.sourceView = self.collectionView
                controller.popoverPresentationController?.sourceRect = cell.frame
                controller.completionWithItemsHandler = { _, completed, _, _ in
                    guard completed else { return }
                    self.viewModel.inputs.operationRequested.send(.none)
                }
                self.present(controller, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.close
            .sink { [weak self] _ in self?.dismiss(animated: true, completion: nil) }
            .store(in: &self.cancellableBag)

        self.navigationItemsProvider.bind(view: self, propagator: dependency.propagator)
        self.toolBarItemsProvider.bind(view: self, propagator: dependency.propagator)
    }

    private func apply(_ operation: ClipCollection.Operation) {
        switch operation {
        case .reordering:
            self.collectionView.setCollectionViewLayout(GridLayout.make(), animated: true)

        default:
            let layout = ClipCollectionLayout()
            layout.delegate = self.clipCollectionProvider
            self.collectionView.setCollectionViewLayout(layout, animated: true)
        }
    }

    private func updateHiddenIconAppearance() {
        self.collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let clip = self.dataSource.itemIdentifier(for: indexPath) else { return }
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell else { return }
            guard clip.isHidden != cell.isHiddenClip else { return }
            cell.setClipHiding(clip.isHidden, animated: true)
        }
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
        self.collectionView.prefetchDataSource = self.clipCollectionProvider
        self.collectionView.contentInsetAdjustmentBehavior = .always

        self.view.addSubview(collectionView)

        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: self.clipCollectionProvider.provideCell(collectionView:indexPath:clip:))

        // Reorder settings

        self.dataSource.reorderingHandlers.canReorderItem = { [weak self] _ in
            return self?.isEditing ?? false
        }

        self.dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            let clipIds = transaction.finalSnapshot.itemIdentifiers.map { $0.id }
            self?.viewModel.inputs.reorder.send(clipIds)
        }

        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.title = self.viewModel.outputs.album.value.title
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

extension AlbumViewController: ClipCollectionProviderDataSource {
    // MARK: - ClipCollectionProviderDataSource

    func isEditing(_ provider: ClipCollectionProvider) -> Bool {
        return self.isEditing
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, clipFor indexPath: IndexPath) -> Clip? {
        return self.dataSource.itemIdentifier(for: indexPath)
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

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddTagsTo clipId: Clip.Identity, at indexPath: IndexPath) {
        guard let viewController = self.factory.makeTagSelectionViewController(
            selectedTags: self.viewModel.outputs.resolveTags(for: clipId),
            context: clipId,
            delegate: self
        ) else {
            return
        }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddToAlbum clipId: Clip.Identity, at indexPath: IndexPath) {
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: clipId, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldRemoveFromAlbum clipId: Clip.Identity, at indexPath: IndexPath) {
        self.viewModel.inputs.removeFromAlbum.send(clipId)
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
        self.viewModel.inputs.reveal.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldHide clipId: Clip.Identity, at indexPath: IndexPath) {
        self.viewModel.inputs.hide.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldShare clipId: Clip.Identity, at indexPath: IndexPath) {
        self.viewModel.inputs.share.send(clipId)
    }

    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldPurge clipId: Clip.Identity, at indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) else {
            RootLogger.shared.write(ConsoleLog(level: .info, message: "Failed to purge clip. Target cell not found"))
            return
        }
        self.presentPurgeAlert(at: cell, in: collectionView) { [weak self] in
            self?.viewModel.inputs.purge.send(clipId)
        }
    }
}

extension AlbumViewController: ClipCollectionAlertPresentable {}

extension AlbumViewController: ClipCollectionNavigationBarProviderDelegate {
    // MARK: - ClipCollectionNavigationBarProviderDelegate

    func didTapEditButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operationRequested.send(.selecting)
    }

    func didTapCancelButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operationRequested.send(.none)
    }

    func didTapSelectAllButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.selectAll.send(())
    }

    func didTapDeselectAllButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.deselectAll.send(())
    }

    func didTapReorderButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operationRequested.send(.reordering)
    }

    func didTapDoneButton(_ provider: ClipCollectionNavigationBarProvider) {
        self.viewModel.inputs.operationRequested.send(.none)
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
        self.viewModel.inputs.revealSelections.send(())
    }

    func shouldCancel(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.operationRequested.send(.none)
    }

    func shouldMerge(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.mergeSelections.send(())
    }

    func shouldShare(_ provider: ClipCollectionToolBarProvider) {
        self.viewModel.inputs.shareSelections.send(())
    }
}

extension AlbumViewController: AlbumSelectionPresenterDelegate {
    // MARK: - AlbumSelectionPresenterDelegate

    func albumSelectionPresenter(_ presenter: AlbumSelectionViewModel, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?) {
        if self.isEditing {
            self.viewModel.inputs.addSelectionsToAlbum.send(albumId)
        } else {
            guard let clipId = context as? Clip.Identity else { return }
            self.viewModel.inputs.addToAlbum.send(.init(target: albumId, clips: Set([clipId])))
        }
    }
}

extension AlbumViewController: TagSelectionDelegate {
    // MARK: - TagSelectionDelegate

    func tagSelection(_ sender: AnyObject, didSelectTags tags: [Tag], withContext context: Any?) {
        let tagIds = Set(tags.map { $0.id })
        if self.isEditing {
            self.viewModel.inputs.addTagsToSelections.send(tagIds)
        } else {
            guard let clipId = context as? Clip.Identity else { return }
            self.viewModel.inputs.replaceTags.send(.init(target: clipId, tags: tagIds))
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

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
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

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension AlbumViewController: ClipMergeViewControllerDelegate {
    // MARK: - ClipMergeViewControllerDelegate

    func didComplete(_ viewController: ClipMergeViewController) {
        self.viewModel.inputs.operationRequested.send(.none)
    }
}

extension AlbumViewController: ClipCollectionViewProtocol {}
