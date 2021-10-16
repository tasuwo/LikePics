//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

public extension Tag {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged var clipCount: Int64
    @NSManaged var id: UUID?
    @NSManaged var isHidden: Bool
    @NSManaged var name: String?
    @NSManaged var clips: NSSet?
}

// MARK: Generated accessors for clips

public extension Tag {
    @objc(addClipsObject:)
    @NSManaged func addToClips(_ value: Clip)

    @objc(removeClipsObject:)
    @NSManaged func removeFromClips(_ value: Clip)

    @objc(addClips:)
    @NSManaged func addToClips(_ values: NSSet)

    @objc(removeClips:)
    @NSManaged func removeFromClips(_ values: NSSet)
}

extension Tag: Identifiable {
}
