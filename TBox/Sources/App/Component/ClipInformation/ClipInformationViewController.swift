//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import Smoothie
import TBoxUIKit
import UIKit

class ClipInformationViewController: UIViewController {
    typealias Layout = ClipInformationViewLayout
    typealias Store = ForestKit.Store<ClipInformationState, ClipInformationAction, ClipInformationDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Service

    private let thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipInformationState,
         dependency: ClipInformationDependency,
         thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable)
    {
        self.store = .init(initialState: state, dependency: dependency, reducer: ClipInformationReducer())
        self.thumbnailLoader = thumbnailLoader
        super.init(nibName: nil, bundle: nil)
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

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipInformationViewController {
    func bind(to store: Store) {
        store.state
            .sink { [weak self] state in
                let snapshot = Self.createSnapshot(items: state.items.orderedFilteredEntities())
                self?.dataSource.apply(snapshot, animatingDifferences: true) {
                    self?.updateCellAppearance()
                }
            }
            .store(in: &subscriptions)
    }

    // MARK: Snapshot

    private static func createSnapshot(items: [ClipItem]) -> Layout.Snapshot {
        var snapshot = Layout.Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(items.map { Layout.Item($0) })

        return snapshot
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

extension ClipInformationViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        dataSource = Layout.configureDataSource(collectionView, thumbnailLoader)
    }
}

extension ClipInformationViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO:
    }
}
