//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol Identifiable {
    associatedtype Identity: Hashable

    var identity: Identity { get }
}

extension Identifiable where Self: Hashable {
    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.identity)
    }
}
