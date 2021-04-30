//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchHistory: Equatable, Hashable, Codable {
    public let id: UUID
    public let query: ClipSearchQuery
    public let date: Date
}
