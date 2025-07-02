//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//
//

import CoreData
import Foundation

extension Tag {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var clipCount: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var isHidden: Bool
    @NSManaged public var name: String?
    @NSManaged public var clips: NSSet?
}

// MARK: Generated accessors for clips

extension Tag {
    @objc(addClipsObject:)
    @NSManaged public func addToClips(_ value: Clip)

    @objc(removeClipsObject:)
    @NSManaged public func removeFromClips(_ value: Clip)

    @objc(addClips:)
    @NSManaged public func addToClips(_ values: NSSet)

    @objc(removeClips:)
    @NSManaged public func removeFromClips(_ values: NSSet)
}

extension Tag: Identifiable {
}
