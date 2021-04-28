//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipSearchQuery: Equatable {
    public let text: String
    public let albumIds: [UUID]
    public let tagIds: [UUID]
    public let sort: ClipSearchSort
    public let isHidden: Bool?

    public var isEmpty: Bool {
        texts.isEmpty && albumIds.isEmpty && tagIds.isEmpty
    }

    public var texts: [String] {
        Array(text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").map { String($0) })
    }

    // MARK: - Initializers

    public init(text: String,
                albumIds: [UUID],
                tagIds: [UUID],
                sort: ClipSearchSort,
                isHidden: Bool?) {
        self.text = text
        self.albumIds = albumIds
        self.tagIds = tagIds
        self.sort = sort
        self.isHidden = isHidden
    }
}
