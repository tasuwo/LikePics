//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

// sourcery: AutoDefaultValue, AutoDefaultValueUsePublic
public struct Tag: Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let isHidden: Bool
    public let clipCount: Int?

    private let _searchableName: String?

    // MARK: - Lifecycle

    // sourcery: AutoDefaultValueUseThisInitializer
    public init(
        id: UUID,
        name: String,
        isHidden: Bool,
        clipCount: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.isHidden = isHidden
        self.clipCount = clipCount

        self._searchableName = name.transformToSearchableText()
    }
}

extension Tag: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}

extension Tag: Searchable {
    public var searchableText: String? {
        return _searchableName
    }
}
