//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipSearchHistory: Equatable, Hashable, Codable, Sendable {
    public let id: UUID
    public let query: ClipSearchQuery
    public let date: Date

    // MARK: - Initializers

    public init(id: UUID, query: ClipSearchQuery, date: Date) {
        self.id = id
        self.query = query
        self.date = date
    }
}
