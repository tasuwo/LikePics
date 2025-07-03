//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public actor UICollectionViewSelectionLazyApplier<Section: Hashable & Sendable, Item: Hashable & Sendable, Entity: Identifiable & Hashable & Codable & Sendable> where Entity.Identity: Sendable {
    private let collectionView: UICollectionView
    private let dataSource: UICollectionViewDiffableDataSource<Section, Item>
    private let itemBuilder: (Entity) -> Item

    private var previousSelections: Set<Entity.Identity> = .init()
    private var suspendedSelections: Set<Entity.Identity> = .init()

    // MARK: - Initializers

    public init(
        collectionView: UICollectionView,
        dataSource: UICollectionViewDiffableDataSource<Section, Item>,
        itemBuilder: @escaping (Entity) -> Item
    ) {
        self.collectionView = collectionView
        self.dataSource = dataSource
        self.itemBuilder = itemBuilder
    }
}

extension UICollectionViewSelectionLazyApplier {
    public func didApplyDataSource(snapshot: EntityCollectionSnapshot<Entity>) async {
        let selections = self.suspendedSelections
        self.suspendedSelections = .init()
        var nextSuspendedSelections = Set<Entity.Identity>()

        // 選択中のEntityが消えていたら、後ほど再度選択させるためにsuspendedSelectionsに積む
        self.previousSelections.subtracting(self.suspendedSelections).forEach { id in
            if snapshot.filteredEntity(having: id) == nil {
                nextSuspendedSelections.insert(id)
            }
        }

        for id in selections {
            guard let entity = snapshot.entity(having: id),
                let indexPath = await self.dataSource.indexPath(for: self.itemBuilder(entity))
            else {
                nextSuspendedSelections.insert(id)
                return
            }
            await self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        self.suspendedSelections = nextSuspendedSelections
    }

    public func applySelection(snapshot: EntityCollectionSnapshot<Entity>) async {
        defer {
            self.previousSelections = snapshot.selectedIds
        }

        let deselections: Set<Entity.Identity> = {
            guard self.previousSelections.isEmpty == false else { return .init() }
            return self.previousSelections.subtracting(snapshot.selectedIds)
        }()

        let selections: Set<Entity.Identity> = {
            guard self.previousSelections.isEmpty == false else {
                return snapshot.selectedIds.union(self.suspendedSelections.subtracting(deselections))
            }
            let additions = snapshot.selectedIds.subtracting(self.previousSelections)
            return additions.union(self.suspendedSelections.subtracting(deselections))
        }()

        self.suspendedSelections = .init()

        var nextSuspendedSelections = Set<Entity.Identity>()

        for id in selections {
            guard let entity = snapshot.filteredEntity(having: id),
                let indexPath = await self.dataSource.indexPath(for: self.itemBuilder(entity))
            else {
                nextSuspendedSelections.insert(id)
                return
            }
            await self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        for id in deselections {
            guard let entity = snapshot.filteredEntity(having: id),
                let indexPath = await self.dataSource.indexPath(for: self.itemBuilder(entity))
            else {
                return
            }
            await self.collectionView.deselectItem(at: indexPath, animated: false)
        }

        self.suspendedSelections = nextSuspendedSelections
    }
}
