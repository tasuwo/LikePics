//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

extension Image {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged public var data: Data?
    @NSManaged public var id: UUID?
}

extension Image: Identifiable {
}
