//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

extension Item {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "ClipItem")
    }

    @NSManaged public var clipId: UUID?
    @NSManaged public var createdDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var imageFileName: String?
    @NSManaged public var imageHeight: Double
    @NSManaged public var imageId: UUID?
    @NSManaged public var imageSize: Int64
    @NSManaged public var imageUrl: URL?
    @NSManaged public var imageWidth: Double
    @NSManaged public var index: Int64
    @NSManaged public var siteUrl: URL?
    @NSManaged public var updatedDate: Date?
    @NSManaged public var clip: Clip?
}

extension Item: Identifiable {
}
