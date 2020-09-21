//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipItemObject: Object {
    @objc dynamic var key: String = ""
    @objc dynamic var clipUrl: String = ""
    @objc dynamic var clipIndex: Int = 0
    @objc dynamic var thumbnailUrl: String? = ""
    @objc dynamic var thumbnailFileName: String = ""
    @objc dynamic var thumbnailHeight: Double = 0
    @objc dynamic var thumbnailWidth: Double = 0
    @objc dynamic var imageFileName: String = ""
    @objc dynamic var imageUrl: String = ""
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "key"
    }

    func makeKey() -> String {
        return "\(self.clipUrl)-\(self.imageUrl)"
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

        return ClipItem(clipUrl: URL(string: managedObject.clipUrl)!,
                        clipIndex: managedObject.clipIndex,
                        thumbnailFileName: managedObject.thumbnailFileName,
                        thumbnailUrl: thumbnailUrl,
                        thumbnailSize: ImageSize(height: managedObject.thumbnailHeight,
                                                 width: managedObject.thumbnailWidth),
                        imageFileName: managedObject.imageFileName,
                        imageUrl: URL(string: managedObject.imageUrl)!,
                        registeredDate: managedObject.registeredAt,
                        updatedDate: managedObject.updatedAt)
    }

    func asManagedObject() -> ClipItemObject {
        let obj = ClipItemObject()
        obj.clipUrl = self.clipUrl.absoluteString
        obj.clipIndex = self.clipIndex
        obj.thumbnailUrl = self.thumbnailUrl?.absoluteString
        obj.thumbnailFileName = self.thumbnailFileName
        obj.thumbnailHeight = self.thumbnailSize.height
        obj.thumbnailWidth = self.thumbnailSize.width
        obj.imageFileName = self.imageFileName
        obj.imageUrl = self.imageUrl.absoluteString
        obj.registeredAt = self.registeredDate
        obj.updatedAt = self.updatedDate

        obj.key = obj.makeKey()

        return obj
    }
}
