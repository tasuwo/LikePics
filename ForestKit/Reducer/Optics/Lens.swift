//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public typealias StateMapping = Lens

public struct Lens<Parent, Child> {
    public let get: (Parent) -> Child
    public let set: (Child, Parent) -> Parent

    public init(get: @escaping (Parent) -> Child,
                set: @escaping (Child, Parent) -> Parent)
    {
        self.get = get
        self.set = set
    }
}

public extension StateMapping {
    init(keyPath: WritableKeyPath<Parent, Child>) {
        get = { $0[keyPath: keyPath] }
        set = {
            var state = $1
            state[keyPath: keyPath] = $0
            return state
        }
    }
}

public func compose<Parent, Child, GrandChild>(lMap: StateMapping<Parent, Child>, rMap: StateMapping<Child, GrandChild>) -> Lens<Parent, GrandChild> {
    return .init(get: { rMap.get(lMap.get($0)) },
                 set: { lMap.set(rMap.set($0, lMap.get($1)), $1) })
}
