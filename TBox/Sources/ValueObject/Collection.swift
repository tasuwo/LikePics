//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct Collection<Value: Identifiable & Codable & Hashable>: Equatable, Codable {
    let _values: [Value.Identity: Ordered<Value>]
    let _selectedIds: Set<Value.Identity>
    let _filteredIds: Set<Value.Identity>

    // MARK: - Initializers

    init(values: [Value.Identity: Ordered<Value>] = [:],
         selectedIds: Set<Value.Identity> = .init(),
         filteredIds: Set<Value.Identity> = .init())
    {
        self._values = values
        self._selectedIds = selectedIds
        self._filteredIds = filteredIds
    }
}

// MARK: - Write

extension Collection {
    func updated(values: [Value.Identity: Ordered<Value>]) -> Self {
        return .init(values: values,
                     selectedIds: _selectedIds,
                     filteredIds: _filteredIds)
    }

    func updated(selectedIds: Set<Value.Identity>) -> Self {
        return .init(values: _values,
                     selectedIds: selectedIds,
                     filteredIds: _filteredIds)
    }

    func updated(filteredIds: Set<Value.Identity>) -> Self {
        return .init(values: _values,
                     selectedIds: _selectedIds,
                     filteredIds: filteredIds)
    }

    func removingValue(having id: Value.Identity) -> Self {
        var removed = false
        let newValues = _values.values
            .sorted(by: { $0.index < $1.index })
            .reduce(into: [Value.Identity: Ordered<Value>](), { dict, orderedValue in
                if removed {
                    dict[orderedValue.value.identity] = Ordered(index: orderedValue.index - 1,
                                                                value: orderedValue.value)
                } else {
                    if orderedValue.value.identity == id {
                        removed = true
                    } else {
                        dict[orderedValue.value.identity] = orderedValue
                    }
                }
            })
        return .init(values: newValues,
                     selectedIds: _selectedIds,
                     filteredIds: _filteredIds)
    }
}

// MARK: - Read

extension Collection {
    func isEmpty() -> Bool {
        return _filteredIds.isEmpty
    }

    func value(having id: Value.Identity) -> Value? {
        return _values[id]?.value
    }

    func orderedValues() -> [Value] {
        _values
            .map { $0.value }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    func selectedIds() -> Set<Value.Identity> {
        _selectedIds
            .intersection(Set(_values.keys))
    }

    func selectedValues() -> Set<Value> {
        Set(_selectedIds.compactMap { _values[$0]?.value })
    }

    func selectedOrderedValues() -> Set<Ordered<Value>> {
        Set(_selectedIds.compactMap { _values[$0] })
    }

    func orderedSelectedValues() -> [Value] {
        _selectedIds
            .compactMap { _values[$0] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    func filteredIds() -> Set<Value.Identity> {
        _filteredIds
            .intersection(Set(_values.keys))
    }

    func filteredValues() -> Set<Value> {
        Set(_filteredIds.compactMap { _values[$0]?.value })
    }

    func filteredOrderedValues() -> Set<Ordered<Value>> {
        Set(_filteredIds.compactMap { _values[$0] })
    }

    func orderedFilteredValues() -> [Value] {
        _filteredIds
            .compactMap { _values[$0] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }
}

// MARK: - Selection/Deselection

extension Collection {
    private var _filteredSelections: Set<Value.Identity> {
        _selectedIds
            .intersection(Set(_values.keys))
            .intersection(_filteredIds)
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
