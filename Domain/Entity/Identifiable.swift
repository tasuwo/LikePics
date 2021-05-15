//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol Identifiable {
    associatedtype Identity: Hashable & Codable

    var identity: Identity { get }
}

public extension Identifiable where Self: Hashable & Codable {
    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.identity)
    }
}
