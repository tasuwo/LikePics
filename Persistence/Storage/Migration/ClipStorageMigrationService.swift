//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable force_unwrapping force_cast force_try

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
            Self.migrateToV2(migration)
        } else if oldSchemaVersion < 3 {
            Self.migrateToV3(migration)
        } else if oldSchemaVersion < 4 {
            Self.migrateToV4(migration)
        } else if oldSchemaVersion < 5 {
            Self.migrateToV5(migration)
        } else if oldSchemaVersion < 6 {
            Self.migrateToV6(migration)
        } else if oldSchemaVersion < 7 {
            Self.migrateToV7(migration)
        } else if oldSchemaVersion < 8 {
            Self.migrateToV8(migration)
        } else if oldSchemaVersion < 9 {
            Self.migrateToV9(migration)
        }
    }

    private static func migrateToV9(_ migration: Migration) {
        let storage = try! ImageStorage()
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, _ in
            try! storage.delete(fileName: oldObject!["thumbnailFileName"] as! String, inClipHaving: oldObject!["clipId"] as! String)
        }
    }

    private static func migrateToV8(_ migration: Migration) {
        let storage = try! ImageStorage()
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
            autoreleasepool {
                let imageFileName = oldObject!["imageFileName"] as! String
                let clipId = oldObject!["clipId"] as! String

                let data = try! storage.readImage(named: imageFileName, inClipHaving: clipId)
                let image = UIImage(data: data)!

                newObject!["imageHeight"] = image.size.height
                newObject!["imageWidth"] = image.size.width
            }
        }
    }

    private static func migrateToV7(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            let clipId = oldObject!["id"] as! String
            let clipUrlString = oldObject!["url"] as! String

            newObject!["url"] = clipUrlString

            migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
                guard oldObject!["clipUrl"] as! String == clipUrlString else { return }

                newObject!["imageUrl"] = oldObject!["imageUrl"]
                newObject!["clipId"] = clipId
            }
        }
    }

    private static func migrateToV6(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { _, newObject in
            newObject!["id"] = UUID().uuidString
        }
        migration.enumerateObjects(ofType: ClipItemObject.className()) { _, newObject in
            newObject!["id"] = UUID().uuidString
        }
    }

    private static func migrateToV5(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
            newObject!["thumbnailUrl"] = oldObject!["thumbnailImageUrl"]
            newObject!["imageUrl"] = oldObject!["largeImageUrl"]

            newObject!["thumbnailFileName"] = "\(UUID().uuidString).jpeg"
            newObject!["imageFileName"] = "\(UUID().uuidString).jpeg"
        }
        migration.deleteData(forType: "ClippedImageObject")
    }

    private static func migrateToV4(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { _, newObject in
            newObject!["isHidden"] = false
        }
    }

    private static func migrateToV3(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { _, newObject in
            newObject!["tags"] = List<TagObject>()
        }
    }

    private static func migrateToV2(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { _, newObject in
            newObject!["registeredAt"] = Date()
            newObject!["updatedAt"] = Date()
        }
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
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
