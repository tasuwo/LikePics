//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

// sourcery: AutoDefaultValue
public struct Tag: Codable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let isHidden: Bool
    public let clipCount: Int?

    private let _searchableName: String?

    // MARK: - Lifecycle

    public init(id: UUID,
                name: String,
                isHidden: Bool,
                clipCount: Int? = nil)
    {
        self.id = id
        self.name = name
        self.isHidden = isHidden
        self.clipCount = clipCount

        self._searchableName = name.transformToSearchableText()
    }

    init(id: UUID,
         name: String,
         isHidden: Bool,
         clipCount: Int?,
         // swiftlint:disable:next identifier_name
         _searchableName: String?)
    {
        self.id = id
        self.name = name
        self.isHidden = isHidden
        self.clipCount = clipCount
        self._searchableName = _searchableName
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