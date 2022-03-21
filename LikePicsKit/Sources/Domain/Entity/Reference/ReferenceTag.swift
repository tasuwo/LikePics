//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

// sourcery: AutoDefaultValuePublic
public struct ReferenceTag: Codable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let isHidden: Bool
    public let isDirty: Bool

    // MARK: - Lifecycle

    public init(id: UUID, name: String, isHidden: Bool, isDirty: Bool = false) {
        self.id = id
        self.name = name
        self.isHidden = isHidden
        self.isDirty = isDirty
    }
}

extension ReferenceTag: Identifiable {
    public typealias Identity = Tag.Identity

    public var identity: Tag.Identity {
        return self.id
    }
}

extension ReferenceTag {
    func map(to: Tag.Type) -> Tag {
        return .init(id: self.id, name: self.name, isHidden: self.isHidden)
    }
}
