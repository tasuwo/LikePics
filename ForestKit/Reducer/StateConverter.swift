//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct StateConverter<Parent: Equatable, Child: Equatable> {
    private let extractBlock: (Parent) -> Child
    private let mergeBlock: (Child, Parent) -> Parent

    public init(extract: @escaping (Parent) -> Child,
                merge: @escaping (Child, Parent) -> Parent)
    {
        extractBlock = extract
        mergeBlock = merge
    }
}

extension StateConverter: StateConvertible {
    public func extract(from parent: Parent) -> Child {
        return extractBlock(parent)
    }

    public func merging(_ child: Child, to parent: Parent) -> Parent {
        return mergeBlock(child, parent)
    }

    public func hasEqualChild(_ lhs: Parent, _ rhs: Parent) -> Bool {
        extract(from: lhs) == extract(from: rhs)
    }
}
