//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import Foundation
import LikePicsUIKit
import Smoothie
import UIKit

class ClipMergeViewController: UIViewController {
    typealias Layout = ClipMergeViewLayout
    typealias Store = ForestKit.Store<ClipMergeViewState, ClipMergeViewAction, ClipMergeViewDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private var proxy: Layout.Proxy!
    private lazy var interactionHandler: URLButtonInteractionHandler = {
        let handler = URLButtonInteractionHandler()
        handler.baseView = view
        return handler
    }()

    // MARK: Service

    private let router: Router
    private let thumbnailPipeline: Pipeline
    private let imageQueryService: ImageQueryServiceProtocol

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private var modalSubscription: Cancellable?
    private let collectionUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipMergeViewController")

    // MARK: - Initializers

    init(state: ClipMergeViewState,
         dependency: ClipMergeViewDependency,
         thumbnailPipeline: Pipeline,
         imageQueryService: ImageQueryServiceProtocol)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: ClipMergeViewReducer())
        self.router = dependency.router
        self.thumbnailPipeline = thumbnailPipeline
        self.imageQueryService = imageQueryService

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        modalSubscription?.cancel()
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureReorder()
        configureNavigationBar()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipMergeViewController {
    private func bind(to store: Store) {
        store.state
            .receive(on: collectionUpdateQueue)
            .removeDuplicates(by: { $0.tags == $1.tags && $0.items == $1.items })
            .sink { [weak self] state in
                self?.dataSource.apply(Layout.createSnapshot(tags: state.tags, items: state.items))
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
            .store(in: &subscriptions)

        store.state
            .bind(\.modal) { [weak self] modal in self?.presentModalIfNeeded(for: modal) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismissAll(completion: nil)
            }
            .store(in: &subscriptions)
    }

    private func presentAlertIfNeeded(for alert: ClipMergeViewState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

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

    private func presentModalIfNeeded(for modal: ClipMergeViewState.Modal?) {
        switch modal {
        case let .tagSelection(id: id, tagIds: selections):
            presentTagSelectionModal(id: id, selections: selections)

        case .none:
            break
        }
    }

    private func presentTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) {
        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModal)
            .sink { [weak self] notification in
                let tags = notification.userInfo?[ModalNotification.UserInfoKey.selectedTags] as? Set<Tag>
                self?.store.execute(.tagsSelected(tags))
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showTagSelectionModal(id: id, selections: selections) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
    }
}

// MARK: - Configuration

extension ClipMergeViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let (dataSource, proxy) = Layout.createDataSource(collectionView, thumbnailPipeline, imageQueryService)
        self.dataSource = dataSource
        self.proxy = proxy
        self.proxy.delegate = self
        self.proxy.interactionDelegate = interactionHandler
    }

    private func configureReorder() {
        collectionView.dragInteractionEnabled = true
        dataSource.reorderingHandlers.canReorderItem = { $0.isClipItem }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            let result = self.createItems(for: self.store.stateValue)
                .applying(transaction.difference)?
                .compactMap { $0.clipItem }
            guard let reorderedItems = result else { return }
            self.store.execute(.itemReordered(reorderedItems))
        }
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    private func createItems(for state: ClipMergeViewState) -> [Layout.Item] {
        return Layout.createItems(tags: state.tags, items: state.items)
    }

    private func configureNavigationBar() {
        navigationItem.title = L10n.clipMergeViewTitle
        navigationItem.leftBarButtonItem = .init(systemItem: .cancel, primaryAction: UIAction(handler: { [weak self] _ in
            self?.store.execute(.cancelButtonTapped)
        }), menu: nil)
        navigationItem.rightBarButtonItem = .init(systemItem: .save, primaryAction: UIAction(handler: { [weak self] _ in
            self?.store.execute(.saveButtonTapped)
        }), menu: nil)
    }
}

extension ClipMergeViewController: ClipMergeViewDelegate {
    // MARK: - ClipMergeViewDelegate

    func didTapTagAdditionButton(_ cell: UICollectionViewCell) {
        store.execute(.tagAdditionButtonTapped)
    }

    func didTapTagDeletionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
              let item = self.dataSource.itemIdentifier(for: indexPath),
              case let .tag(tag) = item else { return }
        store.execute(.tagDeleteButtonTapped(tag.id))
    }

    func didTapSiteUrl(_ sender: UIView, url: URL?) {
        guard let url = url else { return }
        store.execute(.siteUrlButtonTapped(url))
    }
}

extension ClipMergeViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return [] }
        let provider = NSItemProvider(object: item.identifier as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = indexPath
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension ClipMergeViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let sectionValue = destinationIndexPath?.section,
              let section = ClipMergeViewLayout.Section(rawValue: sectionValue),
              section == .clip
        else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
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

extension ClipMergeViewController: UIAdaptivePresentationControllerDelegate {
    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.execute(.didDismissedManually)
    }
}

extension ClipMergeViewController: ModalController {
    // MARK: - ModalController

    var id: UUID { store.stateValue.id }
}

extension ClipMergeViewLayout.Item {
    var isClipItem: Bool {
        switch self {
        case .item:
            return true

        default:
            return false
        }
    }

    var clipItem: ClipItem? {
        switch self {
        case let .item(item):
            return item

        default:
            return nil
        }
    }
}
