//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

enum ClipStorageMigrationService {
    static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            Self.migrationToV1(migration)
        } else if oldSchemaVersion < 2 {
            Self.migraitonToV2(migration)
        } else if oldSchemaVersion < 3 {
            Self.migraitonToV3(migration)
        } else if oldSchemaVersion < 4 {
            Self.migraitonToV4(migration)
        }
    }

    private static func migraitonToV4(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            newObject!["isHidden"] = false
        }
    }

    private static func migraitonToV3(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            newObject!["tags"] = List<TagObject>()
        }
    }

    private static func migraitonToV2(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            newObject!["registeredAt"] = Date()
            newObject!["updatedAt"] = Date()
        }
        migration.enumerateObjects(ofType: ClipItemObject.className()) { oldObject, newObject in
            newObject!["key"] = "\(oldObject!["clipUrl"] as! String)-\(oldObject!["largeImageUrl"] as! String)"
            newObject!["registeredAt"] = Date()
            newObject!["updatedAt"] = Date()
        }
        migration.enumerateObjects(ofType: ClippedImageObject.className()) { oldObject, newObject in
            newObject!["registeredAt"] = Date()
            newObject!["updatedAt"] = Date()
        }
    }

    private static func migrationToV1(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            let clipUrl = oldObject!["url"] as! String

            newObject!["descriptionText"] = nil

            let webImages = oldObject!["webImages"] as! List<MigrationObject>
            webImages.enumerated().forEach { index, webImage in
                let largeImageUrlString = webImage["url"] as! String
                let largeImageData = webImage["image"] as! Data

                // ClippedImage for large image

                let clippedLargeImage = ClippedImageObject()
                clippedLargeImage.clipUrl = clipUrl
                clippedLargeImage.imageUrl = largeImageUrlString
                clippedLargeImage.image = largeImageData
                clippedLargeImage.key = clippedLargeImage.makeKey()
                migration.create(ClippedImageObject.className(), value: clippedLargeImage)

                let largeImageSize = UIImage(data: largeImageData)!.size

                let clipItem = ClipItemObject()
                clipItem.clipUrl = clipUrl
                clipItem.clipIndex = index
                clipItem.thumbnailImageUrl = largeImageUrlString
                clipItem.thumbnailHeight = Double(largeImageSize.height)
                clipItem.thumbnailWidth = Double(largeImageSize.width)
                clipItem.largeImageUrl = largeImageUrlString
                clipItem.largeImageHeight = Double(largeImageSize.height)
                clipItem.largeImageWidth = Double(largeImageSize.width)
                clipItem.key = clipItem.makeKey()

                let createdClipItem = migration.create(ClipItemObject.className(), value: clipItem)

                (newObject!["items"]! as! List<MigrationObject>).append(createdClipItem)
            }
        }
        migration.deleteData(forType: "WebImageObject")
    }
}
