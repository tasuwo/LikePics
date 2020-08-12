//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipItemObject: Object {
    @objc dynamic var key: String = ""
    @objc dynamic var clipUrl: String = ""
    @objc dynamic var clipIndex: Int = 0
    @objc dynamic var thumbnailImageUrl: String = ""
    @objc dynamic var thumbnailHeight: Double = 0
    @objc dynamic var thumbnailWidth: Double = 0
    @objc dynamic var largeImageUrl: String = ""
    @objc dynamic var largeImageHeight: Double = 0
    @objc dynamic var largeImageWidth: Double = 0

    override static func primaryKey() -> String? {
        return "key"
    }

    func makeKey() -> String {
        return "\(self.clipUrl)-\(self.clipIndex)"
    }
}

extension ClipItem: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipItemObject) -> ClipItem {
        return .init(clipUrl: URL(string: managedObject.clipUrl)!,
                     clipIndex: managedObject.clipIndex,
                     thumbnail: .init(url: URL(string: managedObject.thumbnailImageUrl)!,
                                      size: ImageSize(height: managedObject.thumbnailHeight,
                                                      width: managedObject.thumbnailWidth)),
                     image: .init(url: URL(string: managedObject.largeImageUrl)!,
                                  size: ImageSize(height: managedObject.largeImageHeight,
                                                  width: managedObject.largeImageWidth)))
    }

    func asManagedObject() -> ClipItemObject {
        let obj = ClipItemObject()
        obj.clipUrl = self.clipUrl.absoluteString
        obj.clipIndex = self.clipIndex
        obj.thumbnailImageUrl = self.thumbnail.url.absoluteString
        obj.thumbnailWidth = self.thumbnail.size.width
        obj.thumbnailHeight = self.thumbnail.size.height
        obj.largeImageUrl = self.image.url.absoluteString
        obj.largeImageWidth = self.image.size.width
        obj.largeImageHeight = self.image.size.height

        obj.key = obj.makeKey()

        return obj
    }
}
