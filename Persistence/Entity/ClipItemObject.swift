//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipItemObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var clipId: String = ""
    @objc dynamic var clipIndex: Int = 0
    @objc dynamic var thumbnailUrl: String? = ""
    @objc dynamic var thumbnailFileName: String = ""
    @objc dynamic var thumbnailHeight: Double = 0
    @objc dynamic var thumbnailWidth: Double = 0
    @objc dynamic var imageFileName: String = ""
    @objc dynamic var imageUrl: String? = ""
    @objc dynamic var imageHeight: Double = 0
    @objc dynamic var imageWidth: Double = 0
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension ClipItem: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipItemObject) -> ClipItem {
        let thumbnailUrl: URL?
        if let urlString = managedObject.thumbnailUrl {
            thumbnailUrl = URL(string: urlString)
        } else {
            thumbnailUrl = nil
        }

        let imageUrl: URL?
        if let imageUrlString = managedObject.imageUrl {
            imageUrl = URL(string: imageUrlString)
        } else {
            imageUrl = nil
        }

        return ClipItem(id: managedObject.id,
                        clipId: managedObject.clipId,
                        clipIndex: managedObject.clipIndex,
                        thumbnailFileName: managedObject.thumbnailFileName,
                        thumbnailUrl: thumbnailUrl,
                        thumbnailSize: ImageSize(height: managedObject.thumbnailHeight,
                                                 width: managedObject.thumbnailWidth),
                        imageFileName: managedObject.imageFileName,
                        imageUrl: imageUrl,
                        imageSize: ImageSize(height: managedObject.imageHeight,
                                             width: managedObject.imageWidth),
                        registeredDate: managedObject.registeredAt,
                        updatedDate: managedObject.updatedAt)
    }
}
