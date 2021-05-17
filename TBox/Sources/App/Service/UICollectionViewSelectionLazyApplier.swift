//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

class UICollectionViewSelectionLazyApplier<Section: Hashable, Item: Hashable, Entity: Identifiable & Hashable & Codable> {
    private let collectionView: UICollectionView
    private let dataSource: UICollectionViewDiffableDataSource<Section, Item>
    private let itemBuilder: (Entity) -> Item

    private var previousSelections: Set<Entity.Identity> = .init()
    private var suspendedSelections: Set<Entity.Identity> = .init()
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.UICollectionViewSelectionLazyApplier")

    // MARK: - Initializers

    init(collectionView: UICollectionView,
         dataSource: UICollectionViewDiffableDataSource<Section, Item>,
         itemBuilder: @escaping (Entity) -> Item)
    {
        self.collectionView = collectionView
        self.dataSource = dataSource
        self.itemBuilder = itemBuilder
    }
}

extension UICollectionViewSelectionLazyApplier {
    func didApplyDataSource(collection: Collection<Entity>) {
        queue.async {
            let selections = self.suspendedSelections
            self.suspendedSelections = .init()
            var nextSuspendedSelections = Set<Entity.Identity>()

            DispatchQueue.main.sync {
                selections.forEach { id in
                    guard let entity = collection.value(having: id),
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

    func apply(collection: Collection<Entity>) {
        queue.async {
            defer {
                self.previousSelections = collection._selectedIds
            }

            let deselections: Set<Entity.Identity> = {
                guard self.previousSelections.isEmpty == false else { return .init() }
                return self.previousSelections.subtracting(collection._selectedIds)
            }()

            let selections: Set<Entity.Identity> = {
                guard self.previousSelections.isEmpty == false else {
                    return collection._selectedIds.union(self.suspendedSelections.subtracting(deselections))
                }
                let additions = collection._selectedIds.subtracting(self.previousSelections)
                return additions.union(self.suspendedSelections.subtracting(deselections))
            }()

            self.suspendedSelections = .init()

            var nextSuspendedSelections = Set<Entity.Identity>()

            DispatchQueue.main.sync {
                selections.forEach { id in
                    guard let entity = collection.value(having: id),
                          let indexPath = self.dataSource.indexPath(for: self.itemBuilder(entity))
                    else {
                        nextSuspendedSelections.insert(id)
                        return
                    }
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }

                deselections.forEach { id in
                    guard let entity = collection.value(having: id),
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
