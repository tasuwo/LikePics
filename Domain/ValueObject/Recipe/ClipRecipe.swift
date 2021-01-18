//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct ClipRecipe {
    public let id: UUID
    public let description: String?
    public let items: [ClipItemRecipe]
    public let tagIds: [Tag.Identity]
    public let isHidden: Bool
    public let dataSize: Int
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(id: UUID,
                description: String?,
                items: [ClipItemRecipe],
                tagIds: [Tag.Identity],
                isHidden: Bool,
                dataSize: Int,
                registeredDate: Date,
                updatedDate: Date)
    {
        self.id = id
        self.description = description
        self.items = items
        self.tagIds = tagIds
        self.isHidden = isHidden
        self.dataSize = dataSize
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }

    public init(_ clip: Clip, tagIds: [Tag.Identity]) {
        self.id = clip.id
        self.description = clip.description
        self.items = clip.items.map { .init($0) }
        self.tagIds = tagIds
        self.isHidden = clip.isHidden
        self.dataSize = clip.dataSize
        self.registeredDate = clip.registeredDate
        self.updatedDate = clip.updatedDate
    }
}
