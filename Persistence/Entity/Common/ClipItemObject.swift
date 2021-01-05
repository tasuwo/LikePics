//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipItemObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var url: String? = ""
    @objc dynamic var clipId: String = ""
    @objc dynamic var clipIndex: Int = 0
    @objc dynamic var imageId: String = ""
    @objc dynamic var imageFileName: String = ""
    @objc dynamic var imageUrl: String? = ""
    @objc dynamic var imageHeight: Double = 0
    @objc dynamic var imageWidth: Double = 0
    @objc dynamic var imageDataSize: Int = 0
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension ClipItemRecipe {
    static func make(by managedObject: ClipItemObject) -> ClipItemRecipe {
        let imageUrl: URL?
        if let imageUrlString = managedObject.imageUrl {
            imageUrl = URL(string: imageUrlString)
        } else {
            imageUrl = nil
        }

        let url: URL?
        if let urlString = managedObject.url {
            url = URL(string: urlString)
        } else {
            url = nil
        }

        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!,
                     url: url,
                     // swiftlint:disable:next force_unwrapping
                     clipId: UUID(uuidString: managedObject.clipId)!,
                     clipIndex: managedObject.clipIndex,
                     // swiftlint:disable:next force_unwrapping
                     imageId: UUID(uuidString: managedObject.imageId)!,
                     imageFileName: managedObject.imageFileName,
                     imageUrl: imageUrl,
                     imageSize: ImageSize(height: managedObject.imageHeight,
                                          width: managedObject.imageWidth),
                     imageDataSize: managedObject.imageDataSize,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}
