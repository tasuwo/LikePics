//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

extension Clip {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Clip> {
        return NSFetchRequest<Clip>(entityName: "Clip")
    }

    @NSManaged public var createdDate: Date?
    @NSManaged public var descriptionText: String?
    @NSManaged public var id: UUID?
    @NSManaged public var imagesSize: Int64
    @NSManaged public var isHidden: Bool
    @NSManaged public var itemsCount: Int64
    @NSManaged public var updatedDate: Date?
    @NSManaged public var albumItem: NSSet?
    @NSManaged public var clipItems: NSSet?
    @NSManaged public var tags: NSSet?
}

// MARK: Generated accessors for albumItem

extension Clip {
    @objc(addAlbumItemObject:)
    @NSManaged public func addToAlbumItem(_ value: AlbumItem)

    @objc(removeAlbumItemObject:)
    @NSManaged public func removeFromAlbumItem(_ value: AlbumItem)

    @objc(addAlbumItem:)
    @NSManaged public func addToAlbumItem(_ values: NSSet)

    @objc(removeAlbumItem:)
    @NSManaged public func removeFromAlbumItem(_ values: NSSet)
}

// MARK: Generated accessors for clipItems

extension Clip {
    @objc(addClipItemsObject:)
    @NSManaged public func addToClipItems(_ value: Item)

    @objc(removeClipItemsObject:)
    @NSManaged public func removeFromClipItems(_ value: Item)

    @objc(addClipItems:)
    @NSManaged public func addToClipItems(_ values: NSSet)

    @objc(removeClipItems:)
    @NSManaged public func removeFromClipItems(_ values: NSSet)
}

// MARK: Generated accessors for tags

extension Clip {
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}

extension Clip: Identifiable {
}
