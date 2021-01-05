//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

// swiftlint:disable force_unwrapping force_cast

enum ClipStorageMigrationService {
    static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 2 {
            Self.migrationToV1(migration)
        }
    }

    private static func migrationToV1(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            let tagIds = newObject!.dynamicList("tagIds")
            let tags = oldObject!.dynamicList("tags")
            for tag in tags {
                let value = TagIdObject()
                value.id = tag["id"]! as! String
                let obj = migration.create(TagIdObject.className(), value: value)
                tagIds.append(obj)
            }
        }
    }
}
