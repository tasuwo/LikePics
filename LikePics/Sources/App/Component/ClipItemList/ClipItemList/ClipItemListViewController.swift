//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import LikePicsUIKit
import Smoothie
import UIKit

class ClipItemListViewController: UIViewController {
    typealias RootState = ClipItemListRootState
    typealias RootAction = ClipItemListRootAction
    typealias RootDependency = ClipItemListRootDependency
    typealias RootStore = ForestKit.Store<RootState, RootAction, RootDependency>

    typealias Layout = ClipItemListViewLayout
    typealias Store = AnyStoring<ClipItemListState, ClipItemListAction, ClipItemListDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private var selectionApplier: UICollectionViewSelectionLazyApplier<Layout.Section, Layout.Item, ClipItem>!
    private var navigationBar: UINavigationBar!
    private var toolBar: UIToolbar!
    private var toolBarTopConstraint: NSLayoutConstraint!
    private var toolBarBottomConstraint: NSLayoutConstraint!

    private var isToolBarHidden = true {
        didSet {
            toolBarBottomConstraint.isActive = !isToolBarHidden
            toolBarTopConstraint.isActive = isToolBarHidden
            UIView.animate(withDuration: 0.2) {
                self.collectionView.contentInset.bottom = self.isToolBarHidden ? 16 : 44 + 16
                self.view.layoutIfNeeded()
            }
        }
    }

    // MARK: Component

    private var navigationBarController: ClipItemListNavigationBarController!
    private var toolBarController: ClipItemListToolBarController!

    // MARK: Service

    private let thumbnailPipeline: Pipeline
    private let imageQueryService: ImageQueryServiceProtocol

    // MARK: Store

    private var rootStore: RootStore
    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipItemListRootState,
         siteUrlEditAlertState: TextEditAlertState,
         dependency: ClipItemListRootDependency,
         thumbnailPipeline: Pipeline)
    {
        self.imageQueryService = dependency.imageQueryService
        self.rootStore = RootStore(initialState: state, dependency: dependency, reducer: clipItemListRootReducer)
        self.store = rootStore
            .proxy(RootState.mappingToList, RootAction.mappingToList)
            .eraseToAnyStoring()
        self.thumbnailPipeline = thumbnailPipeline
        super.init(nibName: nil, bundle: nil)

        configureComponents(siteUrlEditAlertState)
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

        navigationBarController.viewDidLoad()
        toolBarController.viewDidLoad()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipItemListViewController {
    func bind(to store: Store) {
        store.state
            .removeDuplicates(by: {
                $0.items.filteredOrderedEntities() == $1.items.filteredOrderedEntities()
            })
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                let snapshot = Self.createSnapshot(items: state.items.orderedFilteredEntities())
                self?.dataSource.apply(snapshot, animatingDifferences: true)
                self?.updateCellAppearance()
                self?.selectionApplier.didApplyDataSource(snapshot: state.items)
            }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.items._selectedIds)
            .throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] state in
                self?.selectionApplier.applySelection(snapshot: state.items)
                self?.navigationBarController.store.execute(.updatedSelectionCount(state.items.selectedIds().count))
                self?.toolBarController.store.execute(.selected(state.items.selectedEntities()))
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isEditing) { [weak self] isEditing in
                self?.isEditing = isEditing
                self?.collectionView.isEditing = isEditing
                self?.navigationBarController.store.execute(.editted(isEditing))
            }
            .store(in: &subscriptions)

        store.state
            .bindNoRetain(\.isToolBarHidden, to: \.isToolBarHidden, on: self)
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] in self?.presentAlertIfNeeded(for: $0) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismiss(animated: true, completion: nil)
            }
            .store(in: &subscriptions)

        // アニメーションを崩さないよう、`items` のロードを待たずに初回の更新を行う
        let snapshot = Self.createSnapshot(items: store.stateValue.items.orderedFilteredEntities())
        dataSource.apply(snapshot, animatingDifferences: true)
        updateCellAppearance()
    }

    // MARK: Snapshot

    private static func createSnapshot(items: [ClipItem]) -> Layout.Snapshot {
        var snapshot = Layout.Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(zip(items.indices, items).map { Layout.Item($1, at: $0 + 1, of: items.count) })

        return snapshot
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: ClipItemListState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case let .deletion(item):
            presentDeletionAlert(for: item)

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

    private func presentDeletionAlert(for item: ClipItem) {
        guard let indexPath = dataSource.indexPath(for: .init(item, at: 0, of: 0)), // index は比較に利用されないので適当な値で埋める
              let cell = collectionView.cellForItem(at: indexPath)
        else {
            store.execute(.alertDismissed)
            return
        }

        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipInformationAlertForDeleteAction
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

    // MARK: Appearance

    private func updateCellAppearance() {
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
            guard let cell = collectionView.cellForItem(at: indexPath) as? ClipItemCell else { return }

            guard var configuration = cell.contentConfiguration as? ClipItemContentConfiguration else { return }
            configuration.page = item.order
            configuration.numberOfPage = store.stateValue.items._entities.count
            cell.contentConfiguration = configuration
        }
    }
}

// MARK: - Configuration

extension ClipItemListViewController {
    private func configureComponents(_ siteUrlEditAlertState: TextEditAlertState) {
        let navigationBarStore: ClipItemListNavigationBarController.Store = rootStore
            .proxy(RootState.mappingToNavigationBar, RootAction.mappingToNavigationBar)
            .eraseToAnyStoring()
        navigationBarController = ClipItemListNavigationBarController(store: navigationBarStore)

        let toolBarStore: ClipItemListToolBarController.Store = rootStore
            .proxy(RootState.mappingToToolBar, RootAction.mappingToToolBar)
            .eraseToAnyStoring()
        toolBarController = ClipItemListToolBarController(store: toolBarStore,
                                                          siteUrlEditAlertState: siteUrlEditAlertState,
                                                          imageQueryService: imageQueryService)
        toolBarController.alertHostingViewController = self
    }

    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelectionDuringEditing = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.contentInset.top = 44 + 16

        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))

        let navigationBar = UINavigationBar()
        navigationBar.isTranslucent = true
        navigationBar.delegate = self
        let navigationItem = UINavigationItem()
        navigationBar.items = [navigationItem]
        navigationBarController.navigationItem = navigationItem
        self.navigationBar = navigationBar

        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44)
        ])

        let toolBar = UIToolbar(frame: .init(x: 0, y: 0, width: view.bounds.width, height: 44))
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.isTranslucent = true
        toolBar.delegate = self
        toolBarController.toolBar = toolBar
        self.toolBar = toolBar

        view.addSubview(toolBar)
        toolBarTopConstraint = toolBar.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 8) // borderがはみ出すため、やや下に配置する
        toolBarBottomConstraint = toolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        toolBarBottomConstraint.priority = .init(999)
        let heightConstraint = toolBar.heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.priority = .init(999)
        NSLayoutConstraint.activate([
            toolBarTopConstraint,
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightConstraint
        ])
    }

    private func configureDataSource() {
        collectionView.delegate = self
        dataSource = Layout.configureDataSource(collectionView, thumbnailPipeline, imageQueryService)
        selectionApplier = UICollectionViewSelectionLazyApplier(collectionView: collectionView,
                                                                dataSource: dataSource,
                                                                itemBuilder: { .init($0, at: 0, of: 0) })
    }

    private func configureReorder() {
        collectionView.dragInteractionEnabled = true
        dataSource.reorderingHandlers.canReorderItem = { _ in true }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            let itemIds = transaction.finalSnapshot.itemIdentifiers.map { $0.itemId }
            self?.store.execute(.reordered(itemIds))
        }
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
}

extension ClipItemListViewController: UINavigationBarDelegate {
    // MARK: - UINavigationBarDelegate

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        if bar === navigationBar {
            return .topAttached
        } else if bar === toolBar, !isToolBarHidden {
            return .bottom
        } else {
            return .any
        }
    }
}

extension ClipItemListViewController: UIToolbarDelegate {
    // MARK: - UIToolbarDelegate
}

extension ClipItemListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(item.itemId))
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.deselected(item.itemId))
    }
}

extension ClipItemListViewController {
    // MARK: - UICollectionViewDelegate (Context Menu)

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              let clipItem = store.stateValue.items.entity(having: item.itemId) else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil,
                                          actionProvider: makeActionProvider(for: clipItem, at: indexPath))
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

    private func makeActionProvider(for clipItem: ClipItem, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        let items = ClipItemListMenuBuilder.build(for: clipItem).map {
            makeElement(from: $0, for: clipItem, at: indexPath)
        }
        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeElement(from item: ClipItemListMenuItem, for clipItem: ClipItem, at indexPath: IndexPath) -> UIMenuElement {
        switch item {
        case .delete:
            return UIAction(title: L10n.clipInformationContextMenuDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.deleteMenuTapped(clipItem.id))
            }

        case .copyImageUrl:
            return UIAction(title: L10n.clipInformationContextMenuCopyImageUrl,
                            image: UIImage(systemName: "doc.on.doc"),
                            attributes: []) { [weak self] _ in
                self?.store.execute(.copyImageUrlMenuTapped(clipItem.id))
            }

        case .openImageUrl:
            return UIAction(title: L10n.clipInformationContextMenuOpenImageUrl,
                            image: UIImage(systemName: "globe"),
                            attributes: []) { [weak self] _ in
                self?.store.execute(.openImageUrlMenuTapped(clipItem.id))
            }
        }
    }
}

extension ClipItemListViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return [] }
        let provider = NSItemProvider(object: item.itemId.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension ClipItemListViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
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

extension ClipItemListViewController: ClipItemListPresenting {
    // MARK: - ClipItemListPresenting

    func animatingCell(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool) -> ClipItemListPresentingCell? {
        guard let item = store.stateValue.items._entities[id.itemId],
              let indexPath = dataSource.indexPath(for: .init(item.value, at: 0, of: 0)) else { return nil }

        if needsScroll {
            // セルが画面外だとインスタンスを取り出せないので、表示する
            displayAnimatingCell(animator, id: id)
        }

        let cell = collectionView.cellForItem(at: indexPath) as? ClipItemCell

        return cell
    }

    func animatingCellFrame(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect {
        guard let selectedCell = animatingCell(animator, id: id, needsScroll: needsScroll) else { return .zero }
        return view.convert(selectedCell.frame, to: containerView)
    }

    func animatingCellCornerRadius(_ animator: ClipItemListAnimator) -> CGFloat {
        return 8
    }

    func displayAnimatingCell(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier) {
        guard let item = store.stateValue.items._entities[id.itemId],
              let indexPath = dataSource.indexPath(for: .init(item.value, at: 0, of: 0)) else { return }

        // collectionViewのみでなくviewも再描画しないとセルの座標系がおかしくなる
        // また、scrollToItem呼び出し前に一度再描画しておかないと、正常にスクロールができないケースがある
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)

        // スクロール後に再描画しないと、セルの座標系が更新されない
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
    }

    func thumbnailFrame(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect {
        guard let item = store.stateValue.items._entities[id.itemId] else { return .zero }
        guard let selectedCell = animatingCell(animator, id: id, needsScroll: needsScroll) else { return .zero }
        return selectedCell.convert(selectedCell.calcImageFrame(size: item.value.imageSize.cgSize), to: containerView)
    }

    func baseView(_ animator: ClipItemListAnimator) -> UIView? {
        view
    }

    func componentsOverBaseView(_ animator: ClipItemListAnimator) -> [UIView] {
        []
    }
}
