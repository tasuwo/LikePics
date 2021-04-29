//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipSearchQuery: Equatable {
    public let text: String
    public let tokens: [ClipSearchToken]
    public let isHidden: Bool?
    public let sort: ClipSearchSort

    public var albumIds: [UUID] {
        tokens
            .filter { $0.kind == .album }
            .map { $0.id }
    }

    public var tagIds: [UUID] {
        tokens
            .filter { $0.kind == .tag }
            .map { $0.id }
    }

    public var isEmpty: Bool {
        texts.isEmpty && albumIds.isEmpty && tagIds.isEmpty
    }

    public var texts: [String] {
        Array(text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").map { String($0) })
    }

    // MARK: - Initializers

    public init(text: String, tokens: [ClipSearchToken], isHidden: Bool?, sort: ClipSearchSort) {
        self.text = text
        self.tokens = tokens
        self.isHidden = isHidden
        self.sort = sort
    }
}
