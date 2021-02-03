//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol Identifiable {
    associatedtype Identity: Hashable

    var identity: Identity { get }
}

public extension Identifiable where Self: Hashable {
    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identity)
    }
}
