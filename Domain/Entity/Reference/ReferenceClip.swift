//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct ReferenceClip: Equatable {
    public let id: String
    public let description: String?
    public let tags: [ReferenceTag]
    public let isHidden: Bool
    public let registeredDate: Date
    public let isDirty: Bool

    // MARK: - Lifecycle

    public init(id: String,
                description: String?,
                tags: [ReferenceTag],
                isHidden: Bool,
                registeredDate: Date,
                isDirty: Bool = false)
    {
        self.id = id
        self.description = description
        self.tags = tags
        self.isHidden = isHidden
        self.registeredDate = registeredDate
        self.isDirty = isDirty
    }
}

extension ReferenceClip: Identifiable {
    public typealias Identity = Clip.Identity

    public var identity: Clip.Identity {
        return self.id
    }
}

extension ReferenceClip: Hashable {}
