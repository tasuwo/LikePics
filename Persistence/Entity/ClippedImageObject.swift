//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import RealmSwift

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

    func makeKey() -> String {
        return "\(self.clipUrl)-\(self.imageUrl)"
    }

    static func makeImageKey(ofItem item: ClipItemObject, forThumbnail: Bool) -> String {
        return "\(item.clipUrl)-\(forThumbnail ? item.thumbnailImageUrl : item.largeImageUrl)"
    }

    static func makeKey(byUrl imageUrl: URL, clipUrl: URL) -> String {
        return "\(clipUrl.absoluteString)-\(imageUrl.absoluteString)"
    }
}
