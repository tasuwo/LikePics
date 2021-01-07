//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct Tag: Equatable {
    public let id: UUID
    public let name: String
    public let isHidden: Bool
    public let clipCount: Int?

    public let searchableName: String?

    // MARK: - Lifecycle

    public init(id: UUID, name: String, isHidden: Bool, clipCount: Int? = nil) {
        self.id = id
        self.name = name
        self.isHidden = isHidden
        self.clipCount = clipCount

        self.searchableName = Self.transformToSearchableText(text: name)
    }

    // MARK: - Methods

    static func transformToSearchableText(text: String) -> String? {
        return text
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false)?
            .lowercased()
    }
}

extension Tag: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}

extension Tag: Hashable {}
