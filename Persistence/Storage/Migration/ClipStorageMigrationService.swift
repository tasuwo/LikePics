//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable force_unwrapping

import Domain
import RealmSwift

/**
 * Legacy schema
 */
final class ClippedImageObject: Object {
    @objc dynamic var key: String = ""
    @objc dynamic var clipUrl: String = ""
    @objc dynamic var imageUrl: String = ""
    @objc dynamic var image = Data()
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "key"
    }
}

enum ClipStorageMigrationService {
    static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            fatalError("Unsupported schema version")
        } else if oldSchemaVersion < 2 {
            Self.migraitonToV2(migration)
        } else if oldSchemaVersion < 3 {
            Self.migraitonToV3(migration)
        } else if oldSchemaVersion < 4 {
            Self.migraitonToV4(migration)
        } else if oldSchemaVersion < 5 {
            Self.migraitonToV5(migration)
        }
    }

    private static func migraitonToV5(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
            newObject!["thumbnailUrl"] = oldObject!["thumbnailImageUrl"]
            newObject!["imageUrl"] = oldObject!["largeImageUrl"]

            newObject!["thumbnailFileName"] = "\(UUID().uuidString).jpeg"
            newObject!["imageFileName"] = "\(UUID().uuidString).jpeg"
        }
        migration.deleteData(forType: "ClippedImageObject")
    }

    private static func migraitonToV4(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { _, newObject in
            newObject!["isHidden"] = false
        }
    }

    private static func migraitonToV3(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { _, newObject in
            newObject!["tags"] = List<TagObject>()
        }
    }

    private static func migraitonToV2(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { _, newObject in
            newObject!["registeredAt"] = Date()
            newObject!["updatedAt"] = Date()
        }
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
            // swiftlint:disable:next force_cast
            newObject!["key"] = "\(oldObject!["clipUrl"] as! String)-\(oldObject!["largeImageUrl"] as! String)"
            newObject!["registeredAt"] = Date()
            newObject!["updatedAt"] = Date()
        }
        migration.enumerateObjects(ofType: ClippedImageObject.className()) { _, newObject in
            newObject!["registeredAt"] = Date()
            newObject!["updatedAt"] = Date()
        }
    }
}
