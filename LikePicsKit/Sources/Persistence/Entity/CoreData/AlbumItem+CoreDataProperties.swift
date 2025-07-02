//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

extension AlbumItem {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<AlbumItem> {
        return NSFetchRequest<AlbumItem>(entityName: "AlbumItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var index: Int64
    @NSManaged public var album: Album?
    @NSManaged public var clip: Clip?
}

extension AlbumItem: Identifiable {
}
