//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public typealias ActionMapping = Prism

public struct Prism<Parent: Sendable, Child: Sendable>: Sendable {
    public let build: @Sendable (Child) -> Parent
    public let get: @Sendable (Parent) -> Child?

    public init(
        build: @Sendable @escaping (Child) -> Parent,
        get: @Sendable @escaping (Parent) -> Child?
    ) {
        self.build = build
        self.get = get
    }
}

public func compose<Parent, Child, GrandChild>(lMap: ActionMapping<Parent, Child>, rMap: ActionMapping<Child, GrandChild>) -> ActionMapping<Parent, GrandChild> {
    return .init(
        build: { lMap.build(rMap.build($0)) },
        get: {
            guard let lMapChild = lMap.get($0) else { return nil }
            return rMap.get(lMapChild)
        }
    )
}
