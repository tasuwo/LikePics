//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public extension Item {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "ClipItem")
    }

    @NSManaged var clipId: UUID?
    @NSManaged var createdDate: Date?
    @NSManaged var id: UUID?
    @NSManaged var imageFileName: String?
    @NSManaged var imageHeight: Double
    @NSManaged var imageId: UUID?
    @NSManaged var imageSize: Int64
    @NSManaged var imageUrl: URL?
    @NSManaged var imageWidth: Double
    @NSManaged var index: Int64
    @NSManaged var siteUrl: URL?
    @NSManaged var updatedDate: Date?
    @NSManaged var clip: Clip?
}

extension Item: Identifiable {
}
