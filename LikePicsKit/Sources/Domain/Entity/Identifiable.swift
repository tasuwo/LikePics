//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public protocol Identifiable {
    associatedtype Identity: Hashable, Codable

    var identity: Identity { get }
}

extension Identifiable where Self: Hashable & Codable {
    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.identity)
    }
}
