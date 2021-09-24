//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol SmoothieCompatible {
    associatedtype SmoothieBase

    static var smt: Smoothie<SmoothieBase>.Type { get }

    var smt: Smoothie<SmoothieBase> { get }
}

public struct Smoothie<Base> {
    public let base: Base

    public init(_ base: Base) {
        self.base = base
    }
}

public extension SmoothieCompatible {
    static var smt: Smoothie<Self>.Type { Smoothie<Self>.self }

    var smt: Smoothie<Self> { Smoothie(self) }
}
