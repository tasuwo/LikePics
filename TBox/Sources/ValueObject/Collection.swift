//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct Collection<Value: Identifiable & Equatable & Hashable>: Equatable {
    let _values: [Value.Identity: Ordered<Value>]
    let _selectedIds: Set<Value.Identity>
    let _displayableIds: Set<Value.Identity>
}

extension Collection {
    func value(having id: Value.Identity) -> Value? {
        return _values[id]?.value
    }
}

extension Collection {
    func updated(_values: [Value.Identity: Ordered<Value>]) -> Self {
        return .init(_values: _values,
                     _selectedIds: _selectedIds,
                     _displayableIds: _displayableIds)
    }

    func updated(_selectedIds: Set<Value.Identity>) -> Self {
        return .init(_values: _values,
                     _selectedIds: _selectedIds,
                     _displayableIds: _displayableIds)
    }

    func updated(_displayableIds: Set<Value.Identity>) -> Self {
        return .init(_values: _values,
                     _selectedIds: _selectedIds,
                     _displayableIds: _displayableIds)
    }
}

extension Collection {
    var orderedValues: [Value] {
        _values
            .map { $0.value }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    var selectedValues: [Value] {
        _selectedIds
            .compactMap { _values[$0] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    var displayableValues: [Value] {
        _displayableIds
            .compactMap { _values[$0] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }
}

extension Collection {
    var _validSelections: Set<Value.Identity> {
        _selectedIds
            .filter { _values.keys.contains($0) }
    }

    var _filteredSelections: Set<Value.Identity> {
        _validSelections
            .filter { _displayableIds.contains($0) }
    }

    func selections(from previous: Self?) -> Set<Value> {
        let additions: Set<Value.Identity> = {
            guard let previous = previous else { return _filteredSelections }
            return _filteredSelections.subtracting(previous._filteredSelections)
        }()
        return Set(additions.compactMap { _values[$0]?.value })
    }

    func deselections(from previous: Self?) -> Set<Value> {
        let deletions: Set<Value.Identity> = {
            guard let previous = previous else { return .init() }
            return previous._filteredSelections.subtracting(_filteredSelections)
        }()
        return Set(deletions.compactMap { _values[$0]?.value })
    }
}
