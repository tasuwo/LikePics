//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public extension Album {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }

    @NSManaged var createdDate: Date?
    @NSManaged var id: UUID?
    @NSManaged var index: Int64
    @NSManaged var isHidden: Bool
    @NSManaged var title: String?
    @NSManaged var updatedDate: Date?
    @NSManaged var items: NSSet?
}

// MARK: Generated accessors for items

public extension Album {
    @objc(addItemsObject:)
    @NSManaged func addToItems(_ value: AlbumItem)

    @objc(removeItemsObject:)
    @NSManaged func removeFromItems(_ value: AlbumItem)

    @objc(addItems:)
    @NSManaged func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged func removeFromItems(_ values: NSSet)
}

extension Album: Identifiable {
}
