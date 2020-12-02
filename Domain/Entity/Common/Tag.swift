//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct Tag: Equatable {
    public let id: UUID
    public let name: String
    public let clipCount: Int?

    // MARK: - Lifecycle

    public init(id: UUID, name: String, clipCount: Int? = nil) {
        self.id = id
        self.name = name
        self.clipCount = clipCount
    }
}

extension Tag: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}

extension Tag: Hashable {}
