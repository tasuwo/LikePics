//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct Tag: Equatable {
    public let id: UUID
    public let name: String

    // MARK: - Lifecycle

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}

extension Tag: Hashable {}
