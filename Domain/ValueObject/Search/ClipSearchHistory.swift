//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchHistory: Equatable, Hashable {
    let id: UUID
    let query: ClipSearchQuery
    let date: Date
}
