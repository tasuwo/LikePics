//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public typealias ActionMapping = Prism

public struct Prism<Parent, Child> {
    public let build: (Child) -> Parent
    public let get: (Parent) -> Child?

    public init(build: @escaping (Child) -> Parent,
                get: @escaping (Parent) -> Child?)
    {
        self.build = build
        self.get = get
    }
}

public func compose<Parent, Child, GrandChild>(lMap: ActionMapping<Parent, Child>, rMap: ActionMapping<Child, GrandChild>) -> ActionMapping<Parent, GrandChild> {
    return .init(build: { lMap.build(rMap.build($0)) },
                 get: {
                     guard let lMapChild = lMap.get($0) else { return nil }
                     return rMap.get(lMapChild)
                 })
}
