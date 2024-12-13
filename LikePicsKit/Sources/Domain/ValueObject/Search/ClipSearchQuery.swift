//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipSearchQuery: Equatable, Hashable, Codable, Sendable {
    public let text: String
    public let tokens: [ClipSearchToken]
    public let setting: ClipSearchSetting

    public var isHidden: Bool? { setting.isHidden }

    public var sort: ClipSearchSort { setting.sort }

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
        self.setting = .init(isHidden: isHidden, sort: sort)
    }
}
