//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public extension AlbumItem {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<AlbumItem> {
        return NSFetchRequest<AlbumItem>(entityName: "AlbumItem")
    }

    @NSManaged var id: UUID?
    @NSManaged var index: Int64
    @NSManaged var album: Album?
    @NSManaged var clip: Clip?
}

extension AlbumItem: Identifiable {
}
