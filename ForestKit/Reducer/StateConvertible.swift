//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol StateConvertible {
    associatedtype Parent: Equatable
    associatedtype Child: Equatable

    func extract(from parent: Parent) -> Child
    func merging(_ child: Child, to parent: Parent) -> Parent
    func hasEqualChild(_ lhs: Parent, _ rhs: Parent) -> Bool
}
