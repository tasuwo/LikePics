//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public typealias StateMapping = Lens

public struct Lens<Parent: Sendable, Child: Sendable>: Sendable {
    public let get: @Sendable (Parent) -> Child
    public let set: @Sendable (Child, Parent) -> Parent

    public init(
        get: @Sendable @escaping (Parent) -> Child,
        set: @Sendable @escaping (Child, Parent) -> Parent
    ) {
        self.get = get
        self.set = set
    }
}

extension StateMapping {
    public init(keyPath: WritableKeyPath<Parent, Child>) {
        get = { $0[keyPath: keyPath] }
        set = {
            var state = $1
            state[keyPath: keyPath] = $0
            return state
        }
    }
}

public func compose<Parent, Child, GrandChild>(lMap: StateMapping<Parent, Child>, rMap: StateMapping<Child, GrandChild>) -> Lens<Parent, GrandChild> {
    return .init(
        get: { rMap.get(lMap.get($0)) },
        set: { lMap.set(rMap.set($0, lMap.get($1)), $1) }
    )
}

extension WritableKeyPath: @unchecked @retroactive Sendable {}
