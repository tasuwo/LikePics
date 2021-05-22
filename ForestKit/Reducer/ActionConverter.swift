//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ActionConverter<Parent: Action, Child: Action> {
    private let extractBlock: (Parent) -> Child?
    private let convertBlock: (Child) -> Parent

    public init(extract: @escaping (Parent) -> Child?,
                convert: @escaping (Child) -> Parent)
    {
        extractBlock = extract
        convertBlock = convert
    }
}

extension ActionConverter: ActionConvertible {
    public func extract(from parent: Parent) -> Child? {
        return extractBlock(parent)
    }

    public func convert(_ child: Child) -> Parent {
        return convertBlock(child)
    }
}
