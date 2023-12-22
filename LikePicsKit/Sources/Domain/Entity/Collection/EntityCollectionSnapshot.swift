//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

public struct EntityCollectionSnapshot<Entity: Identifiable & Codable & Hashable>: Equatable, Codable where Entity.ID: Codable {
    private let order: [Entity.ID]

    private let _entities: [Entity.ID: Ordered<Entity>]
    private let _selectedIds: Set<Entity.ID>
    private let _filteredIds: Set<Entity.ID>

    // MARK: - Initializers

    public init(entities: [Entity] = [],
                selectedIds: Set<Entity.ID> = .init(),
                filteredIds: Set<Entity.ID> = .init())
    {
        let order = entities.map(\.id)
        let ids = Set(order)
        self.order = order
        self._entities = entities.indexed()
        self._selectedIds = selectedIds.intersection(ids)
        self._filteredIds = filteredIds.intersection(ids)
    }

    private init(order: [Entity.ID],
                 entities: [Entity.ID: Ordered<Entity>],
                 selectedIds: Set<Entity.ID>,
                 filteredIds: Set<Entity.ID>)
    {
        self.order = order
        self._entities = entities
        self._selectedIds = selectedIds
        self._filteredIds = filteredIds
    }
}

// MARK: - Write

public extension EntityCollectionSnapshot {
    func updated(entities: [Entity]) -> Self {
        return .init(entities: entities,
                     selectedIds: _selectedIds,
                     filteredIds: _filteredIds)
    }

    func selected(_ id: Entity.ID, allowsMultipleSelection: Bool = true, forced: Bool = false) -> Self {
        guard forced || _entities.keys.contains(id) else { return self }
        return .init(order: order,
                     entities: _entities,
                     selectedIds: allowsMultipleSelection ? _selectedIds.union([id]) : Set([id]),
                     filteredIds: _filteredIds)
    }

    func selected(ids: Set<Entity.ID>) -> Self {
        return .init(order: order,
                     entities: _entities,
                     selectedIds: _selectedIds.union(ids).intersection(Set(order)),
                     filteredIds: _filteredIds)
    }

    func selectedAllFilteredEntities() -> Self {
        return .init(order: order,
                     entities: _entities,
                     selectedIds: _filteredIds,
                     filteredIds: _filteredIds)
    }

    func deselected(_ id: Entity.ID) -> Self {
        guard _selectedIds.contains(id) else { return self }
        return .init(order: order,
                     entities: _entities,
                     selectedIds: _selectedIds.subtracting([id]),
                     filteredIds: _filteredIds)
    }

    func deselectedAll() -> Self {
        return .init(order: order,
                     entities: _entities,
                     selectedIds: .init(),
                     filteredIds: _filteredIds)
    }

    func updated(filteredIds: Set<Entity.ID>) -> Self {
        return .init(order: order,
                     entities: _entities,
                     selectedIds: _selectedIds,
                     filteredIds: filteredIds.intersection(Set(_entities.keys)))
    }

    func removingEntity(having id: Entity.ID) -> Self {
        var removed = false

        var newOrder: [Entity.ID] = []
        let newEntities = zip(order.indices, order)
            .reduce(into: [Entity.ID: Ordered<Entity>]()) { dict, element in
                let index = element.0
                let identity = element.1

                guard removed == false else {
                    newOrder.append(identity)
                    // swiftlint:disable force_unwrapping
                    dict[identity] = Ordered(index: index - 1, value: _entities[identity]!.value)
                    return
                }

                if identity == id {
                    removed = true
                } else {
                    newOrder.append(identity)
                    // swiftlint:disable force_unwrapping
                    dict[identity] = _entities[identity]!
                }
            }

        return .init(order: newOrder,
                     entities: newEntities,
                     selectedIds: _selectedIds.subtracting([id]),
                     filteredIds: _filteredIds.subtracting([id]))
    }
}

// MARK: - Read

public extension EntityCollectionSnapshot {
    var ids: Set<Entity.ID> {
        Set(_entities.keys)
    }

    var count: Int {
        _entities.count
    }

    var selectedIds: Set<Entity.ID> {
        _selectedIds
    }

    var filteredIds: Set<Entity.ID> {
        _filteredIds
    }

    func isEmpty() -> Bool {
        return _filteredIds.isEmpty
    }

    func entity(having id: Entity.ID) -> Entity? {
        return _entities[id]?.value
    }

    func orderedEntity(having id: Entity.ID) -> Ordered<Entity>? {
        return _entities[id]
    }

    func orderedEntities() -> [Entity] {
        order
            .compactMap { _entities[$0]?.value }
    }

    func selectedEntities() -> Set<Entity> {
        Set(_selectedIds.compactMap { _entities[$0]?.value })
    }

    func selectedOrderedEntities() -> Set<Ordered<Entity>> {
        Set(_selectedIds.compactMap { _entities[$0] })
    }

    func orderedSelectedEntities() -> [Entity] {
        order
            .filter { _selectedIds.contains($0) }
            .compactMap { _entities[$0]?.value }
    }

    func filteredEntity(having id: Entity.ID) -> Entity? {
        guard _filteredIds.contains(id) else { return nil }
        return _entities[id]?.value
    }

    func filteredEntities() -> Set<Entity> {
        Set(_filteredIds.compactMap { _entities[$0]?.value })
    }

    func filteredOrderedEntities() -> Set<Ordered<Entity>> {
        Set(_filteredIds.compactMap { _entities[$0] })
    }

    func orderedFilteredEntities() -> [Entity] {
        order
            .filter { _filteredIds.contains($0) }
            .compactMap { _entities[$0]?.value }
    }
}
