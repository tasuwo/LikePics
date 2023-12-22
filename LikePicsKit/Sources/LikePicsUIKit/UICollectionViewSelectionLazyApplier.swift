//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class UICollectionViewSelectionLazyApplier<Section: Hashable, Item: Hashable, Entity: Identifiable & Hashable & Codable> where Entity.ID: Codable {
    private let collectionView: UICollectionView
    private let dataSource: UICollectionViewDiffableDataSource<Section, Item>
    private let itemBuilder: (Entity) -> Item

    private var previousSelections: Set<Entity.ID> = .init()
    private var suspendedSelections: Set<Entity.ID> = .init()
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.UICollectionViewSelectionLazyApplier")

    // MARK: - Initializers

    public init(collectionView: UICollectionView,
                dataSource: UICollectionViewDiffableDataSource<Section, Item>,
                itemBuilder: @escaping (Entity) -> Item)
    {
        self.collectionView = collectionView
        self.dataSource = dataSource
        self.itemBuilder = itemBuilder
    }
}

public extension UICollectionViewSelectionLazyApplier {
    func didApplyDataSource(snapshot: EntityCollectionSnapshot<Entity>) {
        queue.async {
            let selections = self.suspendedSelections
            self.suspendedSelections = .init()
            var nextSuspendedSelections = Set<Entity.ID>()

            // 選択中のEntityが消えていたら、後ほど再度選択させるためにsuspendedSelectionsに積む
            self.previousSelections.subtracting(self.suspendedSelections).forEach { id in
                if snapshot.filteredEntity(having: id) == nil {
                    nextSuspendedSelections.insert(id)
                }
            }

            DispatchQueue.main.sync {
                selections.forEach { id in
                    guard let entity = snapshot.entity(having: id),
                          let indexPath = self.dataSource.indexPath(for: self.itemBuilder(entity))
                    else {
                        nextSuspendedSelections.insert(id)
                        return
                    }
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            }

            self.suspendedSelections = nextSuspendedSelections
        }
    }

    func applySelection(snapshot: EntityCollectionSnapshot<Entity>) {
        queue.async {
            defer {
                self.previousSelections = snapshot.selectedIds
            }

            let deselections: Set<Entity.ID> = {
                guard self.previousSelections.isEmpty == false else { return .init() }
                return self.previousSelections.subtracting(snapshot.selectedIds)
            }()

            let selections: Set<Entity.ID> = {
                guard self.previousSelections.isEmpty == false else {
                    return snapshot.selectedIds.union(self.suspendedSelections.subtracting(deselections))
                }
                let additions = snapshot.selectedIds.subtracting(self.previousSelections)
                return additions.union(self.suspendedSelections.subtracting(deselections))
            }()

            self.suspendedSelections = .init()

            var nextSuspendedSelections = Set<Entity.ID>()

            DispatchQueue.main.sync {
                selections.forEach { id in
                    guard let entity = snapshot.filteredEntity(having: id),
                          let indexPath = self.dataSource.indexPath(for: self.itemBuilder(entity))
                    else {
                        nextSuspendedSelections.insert(id)
                        return
                    }
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }

                deselections.forEach { id in
                    guard let entity = snapshot.filteredEntity(having: id),
                          let indexPath = self.dataSource.indexPath(for: self.itemBuilder(entity))
                    else {
                        return
                    }
                    self.collectionView.deselectItem(at: indexPath, animated: false)
                }
            }

            self.suspendedSelections = nextSuspendedSelections
        }
    }
}
