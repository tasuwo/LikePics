//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct ReferenceTag: Equatable {
    public let id: String
    public let name: String

    // MARK: - Lifecycle

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

extension ReferenceTag: Identifiable {
    public typealias Identity = Tag.Identity

    public var identity: Tag.Identity {
        return self.id
    }
}

extension ReferenceTag: Hashable {}
