//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

private class StoringBoxBase<State: Equatable, Action: CompositeKit.Action, Dependency> {
    var stateValue: State { fatalError("abstract") }
    var state: AnyPublisher<State, Never> { fatalError("abstract") }

    // swiftlint:disable:next unavailable_function
    func execute(_ action: Action) { fatalError("abstract") }
}

private class StoringBox<Store: Storing>: StoringBoxBase<Store.State, Store.Action, Store.Dependency> {
    private let base: Store

    override var stateValue: Store.State { base.stateValue }
    override var state: AnyPublisher<Store.State, Never> { base.state }

    init(_ base: Store) {
        self.base = base
    }

    override func execute(_ action: Store.Action) {
        base.execute(action)
    }
}

public class AnyStoring<State: Equatable, Action: CompositeKit.Action, Dependency> {
    private let box: StoringBoxBase<State, Action, Dependency>

    init<Store: Storing>(_ base: Store) where Store.Action == Action,
        Store.State == State,
        Store.Dependency == Dependency
    {
        self.box = StoringBox(base)
    }
}

extension AnyStoring: Storing {
    // MARK: - Storing

    public var stateValue: State { box.stateValue }
    public var state: AnyPublisher<State, Never> { box.state }

    public func execute(_ action: Action) {
        box.execute(action)
    }
}
