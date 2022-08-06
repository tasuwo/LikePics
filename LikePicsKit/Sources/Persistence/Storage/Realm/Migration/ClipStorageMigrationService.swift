//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

// swiftlint:disable force_unwrapping force_cast

enum ClipStorageMigrationService {
    static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            Self.migrationToV1(migration)
        }
        if oldSchemaVersion < 2 {
            Self.migrationToV2(migration)
        }
    }

    private static func migrationToV1(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            let tagIds = newObject!.dynamicList("tagIds")
            let tags = oldObject!.dynamicList("tags")
            for tag in tags {
                let value = TagIdObject()
                value.id = UUID(uuidString: tag["id"]! as! String)!
                let obj = migration.create(TagIdObject.className(), value: value)
                tagIds.append(obj)
            }
        }
    }

    private static func migrationToV2(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
            let idString = oldObject!["id"] as! String
            newObject!["id"] = UUID(uuidString: idString)!

            let clipIdString = oldObject!["clipId"] as! String
            newObject!["clipId"] = UUID(uuidString: clipIdString)!

            let imageIdString = oldObject!["imageId"] as! String
            newObject!["imageId"] = UUID(uuidString: imageIdString)!
        }
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            let idString = oldObject!["id"] as! String
            newObject!["id"] = UUID(uuidString: idString)!
        }
        migration.enumerateObjects(ofType: TagIdObject.className()) { oldObject, newObject in
            let idString = oldObject!["id"] as! String
            newObject!["id"] = UUID(uuidString: idString)!
        }
    }
}
