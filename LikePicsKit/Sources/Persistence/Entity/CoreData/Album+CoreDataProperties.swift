//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

extension Album {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }

    @NSManaged public var createdDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var index: Int64
    @NSManaged public var isHidden: Bool
    @NSManaged public var title: String?
    @NSManaged public var updatedDate: Date?
    @NSManaged public var items: NSSet?
}

// MARK: Generated accessors for items

extension Album {
    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: AlbumItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: AlbumItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}

extension Album: Identifiable {
}
