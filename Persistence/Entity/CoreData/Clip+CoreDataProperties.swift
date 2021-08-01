//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public extension Clip {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Clip> {
        return NSFetchRequest<Clip>(entityName: "Clip")
    }

    @NSManaged var createdDate: Date?
    @NSManaged var descriptionText: String?
    @NSManaged var id: UUID?
    @NSManaged var imagesSize: Int64
    @NSManaged var isHidden: Bool
    @NSManaged var itemsCount: Int64
    @NSManaged var updatedDate: Date?
    @NSManaged var albumItem: NSSet?
    @NSManaged var clipItems: NSSet?
    @NSManaged var tags: NSSet?
}

// MARK: Generated accessors for albumItem

public extension Clip {
    @objc(addAlbumItemObject:)
    @NSManaged func addToAlbumItem(_ value: AlbumItem)

    @objc(removeAlbumItemObject:)
    @NSManaged func removeFromAlbumItem(_ value: AlbumItem)

    @objc(addAlbumItem:)
    @NSManaged func addToAlbumItem(_ values: NSSet)

    @objc(removeAlbumItem:)
    @NSManaged func removeFromAlbumItem(_ values: NSSet)
}

// MARK: Generated accessors for clipItems

public extension Clip {
    @objc(addClipItemsObject:)
    @NSManaged func addToClipItems(_ value: Item)

    @objc(removeClipItemsObject:)
    @NSManaged func removeFromClipItems(_ value: Item)

    @objc(addClipItems:)
    @NSManaged func addToClipItems(_ values: NSSet)

    @objc(removeClipItems:)
    @NSManaged func removeFromClipItems(_ values: NSSet)
}

// MARK: Generated accessors for tags

public extension Clip {
    @objc(addTagsObject:)
    @NSManaged func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged func removeFromTags(_ values: NSSet)
}

extension Clip: Identifiable {
}
