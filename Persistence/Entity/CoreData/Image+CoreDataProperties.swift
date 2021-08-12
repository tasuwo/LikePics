//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public extension Image {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged var data: Data?
    @NSManaged var id: UUID?
}

extension Image: Identifiable {
}
