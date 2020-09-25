//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct Tag {
    public let id: String
    public let name: String

    // MARK: - Lifecycle

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag: Hashable {
    // MARK: - Hashable

    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
