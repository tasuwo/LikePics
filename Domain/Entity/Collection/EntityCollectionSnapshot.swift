//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

public struct EntityCollectionSnapshot<Entity: Identifiable & Codable & Hashable>: Equatable, Codable {
    public let _entities: [Entity.Identity: Ordered<Entity>]
    public let _selectedIds: Set<Entity.Identity>
    public let _filteredIds: Set<Entity.Identity>

    // MARK: - Initializers

    public init(entities: [Entity.Identity: Ordered<Entity>] = [:],
                selectedIds: Set<Entity.Identity> = .init(),
                filteredIds: Set<Entity.Identity> = .init())
    {
        self._entities = entities
        self._selectedIds = selectedIds
        self._filteredIds = filteredIds
    }
}

// MARK: - Write

public extension EntityCollectionSnapshot {
    func updated(entities: [Entity.Identity: Ordered<Entity>]) -> Self {
        return .init(entities: entities,
                     selectedIds: _selectedIds,
                     filteredIds: _filteredIds)
    }

    func updated(selectedIds: Set<Entity.Identity>) -> Self {
        return .init(entities: _entities,
                     selectedIds: selectedIds,
                     filteredIds: _filteredIds)
    }

    func updated(filteredIds: Set<Entity.Identity>) -> Self {
        return .init(entities: _entities,
                     selectedIds: _selectedIds,
                     filteredIds: filteredIds)
    }

    func removingEntity(having id: Entity.Identity) -> Self {
        var removed = false
        let newEntities = _entities.values
            .sorted(by: { $0.index < $1.index })
            .reduce(into: [Entity.Identity: Ordered<Entity>](), { dict, orderedEntity in
                if removed {
                    dict[orderedEntity.value.identity] = Ordered(index: orderedEntity.index - 1,
                                                                 value: orderedEntity.value)
                } else {
                    if orderedEntity.value.identity == id {
                        removed = true
                    } else {
                        dict[orderedEntity.value.identity] = orderedEntity
                    }
                }
            })
        return .init(entities: newEntities,
                     selectedIds: _selectedIds,
                     filteredIds: _filteredIds)
    }
}

// MARK: - Read

public extension EntityCollectionSnapshot {
    func isEmpty() -> Bool {
        return _filteredIds.isEmpty
    }

    func entity(having id: Entity.Identity) -> Entity? {
        return _entities[id]?.value
    }

    func orderedEntities() -> [Entity] {
        _entities
            .map { $0.value }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    func selectedIds() -> Set<Entity.Identity> {
        _selectedIds
            .intersection(Set(_entities.keys))
    }

    func selectedEntities() -> Set<Entity> {
        Set(_selectedIds.compactMap { _entities[$0]?.value })
    }

    func selectedOrderedEntities() -> Set<Ordered<Entity>> {
        Set(_selectedIds.compactMap { _entities[$0] })
    }

    func orderedSelectedEntities() -> [Entity] {
        _selectedIds
            .compactMap { _entities[$0] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    func filteredIds() -> Set<Entity.Identity> {
        _filteredIds
            .intersection(Set(_entities.keys))
    }

    func filteredEntities() -> Set<Entity> {
        Set(_filteredIds.compactMap { _entities[$0]?.value })
    }

    func filteredOrderedEntities() -> Set<Ordered<Entity>> {
        Set(_filteredIds.compactMap { _entities[$0] })
    }

    func orderedFilteredEntities() -> [Entity] {
        _filteredIds
            .compactMap { _entities[$0] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }
}
