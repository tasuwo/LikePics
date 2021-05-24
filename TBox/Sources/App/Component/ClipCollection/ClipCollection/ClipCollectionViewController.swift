//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import Smoothie
import TBoxUIKit
import UIKit

class ClipCollectionViewController: UIViewController {
    typealias RootState = ClipCollectionViewRootState
    typealias RootAction = ClipCollectionViewRootAction
    typealias RootDependency = ClipCollectionViewRootDependency
    typealias RootStore = ForestKit.Store<RootState, RootAction, RootDependency>

    typealias Layout = ClipCollectionViewLayout
    typealias Store = AnyStoring<ClipCollectionState, ClipCollectionAction, ClipCollectionDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private var selectionApplier: UICollectionViewSelectionLazyApplier<Layout.Section, Layout.Item, Clip>!
    private var preLoader: ClipCollectionPreLoader!
    private let emptyMessageView = EmptyMessageView()

    // MARK: Component

    private var navigationBarController: ClipCollectionNavigationBarController!
    private var toolBarController: ClipCollectionToolBarController!

    // MARK: Service

    private let router: Router
    private let thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable
    private let menuBuilder: ClipCollectionMenuBuildable

    // MARK: Store

    private var rootStore: RootStore
    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private var modalSubscription: Cancellable?
    private let clipsUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipCollectionViewCotnroller", qos: .userInteractive)

    // MARK: Privates

    private let imageQueryService: ImageQueryServiceProtocol

    // MARK: - Initializers

    init(state: ClipCollectionViewRootState,
         dependency: ClipCollectionViewRootDependency,
         thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable,
         menuBuilder: ClipCollectionMenuBuildable)
    {
        self.router = dependency.router
        self.thumbnailLoader = thumbnailLoader
        self.menuBuilder = menuBuilder
        self.imageQueryService = dependency.imageQueryService

        let rootStore = RootStore(initialState: state, dependency: dependency, reducer: clipCollectionViewRootReducer)
        self.rootStore = rootStore
        self.store = rootStore
            .proxy(RootState.clipCollectionConverter, RootAction.clipCollectionConverter)
            .eraseToAnyStoring()

        super.init(nibName: nil, bundle: nil)

        let navigationBarStore: ClipCollectionNavigationBarController.Store = rootStore
            .proxy(RootState.navigationBarConverter, RootAction.navigationBarConverter)
            .eraseToAnyStoring()
        navigationBarController = ClipCollectionNavigationBarController(store: navigationBarStore, dependency: dependency)

        let toolBarStore: ClipCollectionToolBarController.Store = rootStore
            .proxy(RootState.toolBarConverter, RootAction.toolBarConverter)
            .eraseToAnyStoring()
        toolBarController = ClipCollectionToolBarController(store: toolBarStore, dependency: dependency)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureReorder()
        configureEmptyMessageView()

        navigationBarController.navigationItem = navigationItem
        toolBarController.toolBarHostingViewController = self
        toolBarController.alertHostingViewController = self

        navigationBarController.viewDidLoad()
        toolBarController.viewDidLoad()

        bind(to: rootStore)
        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        store.execute(.viewDidAppear)

        updateUserActivity(rootStore.stateValue)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

// MARK: - Bind (Root)

extension ClipCollectionViewController {
    private func bind(to store: RootStore) {
        store.state
            .removeDuplicates(by: RootState.toolBarConverter.hasEqualChild(_:_:))
            .sink { [weak self] _ in self?.toolBarController.store.execute(.stateChanged) }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: RootState.navigationBarConverter.hasEqualChild(_:_:))
            .sink { [weak self] _ in self?.navigationBarController.store.execute(.stateChanged) }
            .store(in: &subscriptions)

        store.state
            .receive(on: DispatchQueue.global())
            .removeDuplicates(by: { $0.removingSessionStates() == $1.removingSessionStates() })
            .debounce(for: 3, scheduler: DispatchQueue.global())
            .sink { [weak self] state in self?.updateUserActivity(state) }
            .store(in: &subscriptions)
    }

    // MARK: User Activity

    private func updateUserActivity(_ state: ClipCollectionViewRootState) {
        DispatchQueue.global().async {
            guard let data = try? JSONEncoder().encode(Intent.clips(state.removingSessionStates(), preview: nil)),
                  let string = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self.view.window?.windowScene?.userActivity = NSUserActivity.make(with: string)
            }
        }
    }
}

// MARK: - Bind

extension ClipCollectionViewController {
    private func bind(to store: Store) {
        store.state
            .filter { !$0.clips.isEmpty() }
            .removeDuplicates(by: \.clips)
            .throttle(for: 0.5, scheduler: RunLoop.main, latest: false)
            .receive(on: clipsUpdateQueue)
            .removeDuplicates(by: { $0.clips.filteredOrderedEntities() == $1.clips.filteredOrderedEntities() })
            .sink { [weak self] state in
                var snapshot = Layout.Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(state.clips.orderedFilteredEntities().map({ .init($0) }))
                self?.dataSource.apply(snapshot, animatingDifferences: true) {
                    self?.updateHiddenIconAppearance()
                }
                self?.selectionApplier.didApplyDataSource(snapshot: state.clips)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.title, to: \.title, on: navigationItem)
            .store(in: &subscriptions)

        store.state
            .bind(\.isCollectionViewHidden, to: \.isHidden, on: collectionView)
            .store(in: &subscriptions)
        store.state
            .bind(\.isDragInteractionEnabled, to: \.dragInteractionEnabled, on: collectionView)
            .store(in: &subscriptions)

        store.state
            .bind(\.emptyMessageViewAlpha, to: \.alpha, on: emptyMessageView)
            .store(in: &subscriptions)

        store.state
            .bindNoRetain(\.isEditing, to: \.isEditing, on: self)
            .store(in: &subscriptions)
        store.state
            .bind(\.isEditing, to: \.isEditing, on: collectionView)
            .store(in: &subscriptions)
        store.state
            .bind(\.isEditing) { [weak self] isEditing in
                self?.collectionView.visibleCells
                    .compactMap { $0 as? ClipCollectionViewCell }
                    .forEach { $0.isEditing = isEditing }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.layout) { [weak self] layout in
                self?.applyLayout(layout)
            }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.clips._selectedIds)
            .throttle(for: 0.5, scheduler: RunLoop.main, latest: false)
            .sink { [weak self] state in self?.selectionApplier.applySelection(snapshot: state.clips) }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.alert)
            .sink { [weak self] state in self?.presentAlertIfNeeded(for: state) }
            .store(in: &subscriptions)

        store.state
            .bind(\.modal) { [weak self] modal in self?.presentModalIfNeeded(for: modal) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismiss(animated: true, completion: nil)
            }
            .store(in: &subscriptions)
    }

    // MARK: Layout

    private func applyLayout(_ layout: ClipCollection.Layout) {
        let nextLayout = Layout.createLayout(layout.toRequest(delegate: self))
        let animationBlocks = collectionView.visibleCells
            .compactMap { $0 as? ClipCollectionViewCell }
            .map { $0.setThumbnailTypeWithAnimationBlocks(toSingle: layout.isSingleThumbnail) }

        UIView.animate(withDuration: 0.25) {
            self.collectionView.setCollectionViewLayout(nextLayout, animated: true)
            animationBlocks.forEach { $0() }
        }
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for state: ClipCollectionState) {
        switch state.alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case let .deletion(clipId: clipId):
            presentDeletionAlert(for: clipId, state: state)

        case let .purge(clipId: clipId):
            presentPurgeAlert(for: clipId, state: state)

        case let .share(clipId: clipId, imageIds: imageIds):
            presentShareAlert(for: clipId, imageIds: imageIds, state: state)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        self.present(alert, animated: true, completion: nil)
    }

    private func presentPurgeAlert(for clipId: Clip.Identity, state: ClipCollectionState) {
        guard let clip = state.clips.entity(having: clipId),
              let indexPath = dataSource.indexPath(for: .init(clip)),
              let cell = collectionView.cellForItem(at: indexPath)
        else {
            store.execute(.alertDismissed)
            return
        }

        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForPurgeMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForPurgeAction, style: .destructive, handler: { [weak self] _ in
            self?.store.execute(.alertPurgeConfirmed)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }

    private func presentDeletionAlert(for clipId: Clip.Identity, state: ClipCollectionState) {
        guard let clip = state.clips.entity(having: clipId),
              let indexPath = dataSource.indexPath(for: .init(clip)),
              let cell = collectionView.cellForItem(at: indexPath)
        else {
            store.execute(.alertDismissed)
            return
        }

        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForDeleteAction(1)
        alert.addAction(.init(title: title, style: .destructive, handler: { [weak self] _ in
            self?.store.execute(.alertDeleteConfirmed)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }

    private func presentShareAlert(for clipId: Clip.Identity, imageIds: [ImageContainer.Identity], state: ClipCollectionState) {
        let items = imageIds.map { ClipItemImageShareItem(imageId: $0, imageQueryService: imageQueryService) }
        guard let clip = state.clips.entity(having: clipId),
              let indexPath = dataSource.indexPath(for: .init(clip)),
              let cell = collectionView.cellForItem(at: indexPath)
        else {
            store.execute(.alertDismissed)
            return
        }

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = self.collectionView
        controller.popoverPresentationController?.sourceRect = cell.frame
        controller.completionWithItemsHandler = { [weak self] activity, success, _, _ in
            if success {
                self?.store.execute(.alertShareDismissed(true))
            } else {
                if activity == nil {
                    self?.store.execute(.alertShareDismissed(false))
                } else {
                    // NOP
                }
            }
        }

        self.present(controller, animated: true, completion: nil)
    }

    // MARK: Modal

    private func presentModalIfNeeded(for modal: ClipCollectionState.Modal?) {
        switch modal {
        case .albumSelection:
            presentAlbumSelectionModal()

        case let .tagSelection(tagIds: tagIds):
            presentTagSelectionModal(selections: tagIds)

        case let .clipEdit(clipId: clipId):
            presentClipEditModal(clipId: clipId)

        case let .clipMerge(clips: clips):
            presentClipMergeModal(clips: clips)

        case .none:
            break
        }
    }

    private func presentAlbumSelectionModal() {
        let id = UUID()

        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .albumSelectionModal)
            .sink { [weak self] notification in
                let albumId = notification.userInfo?[ModalNotification.UserInfoKey.selectedAlbumId] as? Album.Identity
                self?.store.execute(.albumsSelected(albumId))
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showAlbumSelectionModal(id: id) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
    }

    private func presentTagSelectionModal(selections: Set<Tag.Identity>) {
        let id = UUID()

        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModal)
            .sink { [weak self] notification in
                if let tags = notification.userInfo?[ModalNotification.UserInfoKey.selectedTags] as? Set<Tag> {
                    self?.store.execute(.tagsSelected(Set(tags.map({ $0.id }))))
                } else {
                    self?.store.execute(.tagsSelected(nil))
                }
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showTagSelectionModal(id: id, selections: selections) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
    }

    private func presentClipEditModal(clipId: Clip.Identity) {
        let id = UUID()

        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .clipEditModal)
            .sink { [weak self] _ in
                self?.store.execute(.modalCompleted(true))
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showClipEditModal(id: id, clipId: clipId) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
    }

    private func presentClipMergeModal(clips: [Clip]) {
        let id = UUID()

        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .clipMergeModal)
            .sink { [weak self] notification in
                let isCompleted = notification.userInfo?[ModalNotification.UserInfoKey.clipMergeCompleted] as? Bool
                self?.store.execute(.modalCompleted(isCompleted ?? false))
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showClipMergeModal(id: id, clips: clips) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
    }

    // MARK: Appearance

    private func updateHiddenIconAppearance() {
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let clip = dataSource.itemIdentifier(for: indexPath) else { return }
            guard let cell = collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell else { return }
            guard clip.isHidden != cell.isHiddenClip else { return }
            cell.setClipHiding(clip.isHidden, animated: true)
        }
    }
}

// MARK: - Configuration

extension ClipCollectionViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        let layout = Layout.createLayout(store.stateValue.layout.toRequest(delegate: self))
        collectionView = ClipCollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelectionDuringEditing = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))

        emptyMessageView.alpha = 0
        view.addSubview(self.emptyMessageView)
        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        dataSource = Layout.configureDataSource(collectionView: collectionView, thumbnailLoader: thumbnailLoader)
        selectionApplier = UICollectionViewSelectionLazyApplier(collectionView: collectionView,
                                                                dataSource: dataSource,
                                                                itemBuilder: { .init($0) })

        // カスタムレイアウトとPreloadの相性が悪い？poolが解放されずに残ってしまうので、一旦無効にする
        // preLoader = .init(dataSource: dataSource, thumbnailLoader: thumbnailLoader)
        // collectionView.isPrefetchingEnabled = true
        // collectionView.prefetchDataSource = preLoader
    }

    private func configureReorder() {
        collectionView.dragInteractionEnabled = false
        dataSource.reorderingHandlers.canReorderItem = { [weak self] _ in self?.isEditing == false }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            let clipIds = transaction.finalSnapshot.itemIdentifiers.map { $0.id }
            self?.store.execute(.reordered(clipIds))
        }
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    private func configureEmptyMessageView() {
        emptyMessageView.title = store.stateValue.source.emptyMessageViewTitle
        emptyMessageView.message = store.stateValue.source.emptyMessageViewMessage
        emptyMessageView.isMessageHidden = store.stateValue.source.isEmptyMessageViewMessageHidden
        emptyMessageView.isActionButtonHidden = store.stateValue.source.isEmptyMessageViewActionButtonHidden
    }
}

extension ClipCollectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clip = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(clip.id))
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let clip = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.deselected(clip.id))
    }
}

extension ClipCollectionViewController {
    // MARK: - UICollectionViewDelegate (Context Menu)

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath), !isEditing else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil,
                                          actionProvider: self.makeActionProvider(for: item.clip, at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return UITargetedPreview.create(for: configuration, collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return UITargetedPreview.create(for: configuration, collectionView: collectionView)
    }

    private func makeActionProvider(for clip: Clip, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        let items = menuBuilder.build(for: clip, source: store.stateValue.source).map {
            self.makeElement(from: $0, for: clip, at: indexPath)
        }
        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeElement(from element: ClipCollection.MenuElement, for clip: Clip, at indexPath: IndexPath) -> UIMenuElement {
        switch element {
        case let .item(item):
            return self.makeElement(from: item, for: clip, at: indexPath)

        case let .subMenu(subMenu):
            let title = Self.resolveTitle(for: subMenu.kind)
            let icon = Self.resolveIcon(for: subMenu.kind)
            let children = subMenu.children.map { self.makeElement(from: $0, for: clip, at: indexPath) }
            return UIMenu(title: title, image: icon, options: subMenu.isInline ? .displayInline : [], children: children)
        }
    }

    private static func resolveTitle(for kind: ClipCollection.SubMenu.Kind) -> String {
        switch kind {
        case .add:
            return L10n.clipsListContextMenuAdd

        case .others:
            return L10n.clipsListContextMenuOthers
        }
    }

    private static func resolveIcon(for kind: ClipCollection.SubMenu.Kind) -> UIImage? {
        switch kind {
        case .add:
            return UIImage(systemName: "plus")

        case .others:
            return UIImage(systemName: "ellipsis")
        }
    }

    private func makeElement(from item: ClipCollection.MenuItem, for clip: Clip, at indexPath: IndexPath) -> UIMenuElement {
        switch item {
        case .addTag:
            return UIAction(title: L10n.clipsListContextMenuAddTag,
                            image: UIImage(systemName: "tag.fill")) { [weak self] _ in
                self?.store.execute(.tagAdditionMenuTapped(clip.id))
            }

        case .addToAlbum:
            return UIAction(title: L10n.clipsListContextMenuAddToAlbum,
                            image: UIImage(systemName: "rectangle.stack.fill.badge.plus")) { [weak self] _ in
                self?.store.execute(.albumAdditionMenuTapped(clip.id))
            }

        case .reveal:
            return UIAction(title: L10n.clipsListContextMenuReveal,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                self?.store.execute(.revealMenuTapped(clip.id))
            }

        case .hide:
            return UIAction(title: L10n.clipsListContextMenuHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                self?.store.execute(.hideMenuTapped(clip.id))
            }

        case .removeFromAlbum:
            return UIAction(title: L10n.clipsListContextMenuRemoveFromAlbum,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.removeFromAlbumMenuTapped(clip.id))
            }

        case .delete:
            return UIAction(title: L10n.clipsListContextMenuDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.deleteMenuTapped(clip.id))
            }

        case .share:
            return UIAction(title: L10n.clipsListContextMenuShare,
                            image: UIImage(systemName: "square.and.arrow.up.fill")) { [weak self] _ in
                self?.store.execute(.shareMenuTapped(clip.id))
            }

        case .purge:
            return UIAction(title: L10n.clipsListContextMenuPurge,
                            image: UIImage(systemName: "scissors"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.purgeMenuTapped(clip.id))
            }

        case .edit:
            return UIAction(title: L10n.clipsListContextMenuEdit,
                            image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.store.execute(.editMenuTapped(clip.id))
            }
        }
    }
}

extension ClipCollectionViewController: ClipCollectionWaterfallLayoutDelegate {
    // MARK: - ClipCollectionWaterfallLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, thumbnailHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard let clip = dataSource.itemIdentifier(for: indexPath) else { return .zero }

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        case let (.some(item), .some, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipCollectionViewCell.secondaryStickingOutMargin

        case let (.some(item), .some, .some):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipCollectionViewCell.secondaryStickingOutMargin
                + ClipCollectionViewCell.tertiaryStickingOutMargin

        case let (.some(item), _, _):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        default:
            return width
        }
    }
}

extension ClipCollectionViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var previewingClip: Clip? {
        store.stateValue.previewingClip
    }

    var previewingCell: ClipPreviewPresentingCell? {
        guard let clip = previewingClip, let indexPath = dataSource.indexPath(for: .init(clip)) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell
    }

    var previewingCellCornerRadius: CGFloat {
        return ClipCollectionViewCell.cornerRadius
    }

    var previewingCollectionView: UICollectionView {
        collectionView
    }

    func displayPreviewingCell() {
        guard let clip = previewingClip, let indexPath = dataSource.indexPath(for: .init(clip)) else { return }

        // collectionViewのみでなくviewも再描画しないとセルの座標系がおかしくなる
        // また、scrollToItem呼び出し前に一度再描画しておかないと、正常にスクロールができないケースがある
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)

        // スクロール後に再描画しないと、セルの座標系が更新されない
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
    }
}

extension ClipCollectionViewController: UICollectionViewDragDelegate {
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

extension ClipCollectionViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return self.isEditing == false
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

// MARK: - Empty Message View Configuration

extension ClipCollection.Source {
    var emptyMessageViewTitle: String {
        switch self {
        case .all:
            return L10n.topClipViewEmptyTitle

        case .album:
            return L10n.albumViewEmptyTitle

        case let .tag(tag):
            return L10n.searchResultForTagEmptyTitle(tag.name)

        case .uncategorized:
            return L10n.searchResultForUncategorizedEmptyTitle

        case .search:
            return L10n.searchResultNotFoundTitle
        }
    }

    var emptyMessageViewMessage: String? {
        switch self {
        case .all:
            return L10n.topClipViewEmptyMessage

        case let .search(query):
            return L10n.searchResultNotFoundMessage(query.displayTitle)

        default:
            return nil
        }
    }

    var isEmptyMessageViewMessageHidden: Bool {
        switch self {
        case .all:
            return false

        default:
            return true
        }
    }

    var isEmptyMessageViewActionButtonHidden: Bool {
        return true
    }
}
