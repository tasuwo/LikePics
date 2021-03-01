//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class ClipMergeViewController: UIViewController {
    typealias Layout = ClipMergeViewLayout
    typealias Store = LikePics.Store<ClipMergeViewState, ClipMergeViewAction, ClipMergeViewDependency>

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

    private let thumbnailLoader: ThumbnailLoaderProtocol

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipMergeViewState,
         dependency: ClipMergeViewDependency,
         thumbnailLoader: ThumbnailLoaderProtocol)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: ClipMergeViewReducer.self)
        self.thumbnailLoader = thumbnailLoader

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureReorder()
        configureNavigationBar()

        bind(to: store)
    }
}

// MARK: - Bind

extension ClipMergeViewController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.global().async {
                self.dataSource.apply(Layout.createSnapshot(tags: state.tags, items: state.items))
            }

            self.presentAlertIfNeeded(for: state.alert)

            if state.isDismissed {
                self.dismiss(animated: true, completion: nil)
            }
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
}

// MARK: - Configuration

extension ClipMergeViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let (dataSource, proxy) = Layout.createDataSource(collectionView: collectionView, thumbnailLoader: thumbnailLoader)
        self.dataSource = dataSource
        self.proxy = proxy
        self.proxy.delegate = self
        self.proxy.interactionDelegate = interactionHandler
    }

    private func configureReorder() {
        collectionView.dragInteractionEnabled = true
        dataSource.reorderingHandlers.canReorderItem = {
            switch $0 {
            case .item:
                return true

            default:
                return false
            }
        }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            let tags = self.store.stateValue.tags
            let items = self.store.stateValue.items
            let orderedResult = Layout.createItems(tags: tags, items: items).applying(transaction.difference)
            let nullableOrderedItems = orderedResult?.compactMap { item -> ClipItem? in
                switch item {
                case let .item(clipItem):
                    return clipItem

                default:
                    return nil
                }
            }
            guard let orderedItems = nullableOrderedItems else { return }
            self.store.execute(.itemReordered(orderedItems))
        }
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
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
