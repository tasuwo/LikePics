//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct StateConverter<Parent: Equatable, Child: Equatable> {
    private let extractBlock: (Parent) -> Child
    private let mergeBlock: (Child, Parent) -> Parent

    init(extract: @escaping (Parent) -> Child,
         merge: @escaping (Child, Parent) -> Parent)
    {
        extractBlock = extract
        mergeBlock = merge
    }
}

extension StateConverter: StateConvertible {
    func extract(from parent: Parent) -> Child {
        return extractBlock(parent)
    }

    func merging(_ child: Child, to parent: Parent) -> Parent {
        return mergeBlock(child, parent)
    }

    func hasEqualChild(_ lhs: Parent, _ rhs: Parent) -> Bool {
        extract(from: lhs) == extract(from: rhs)
    }
}
