//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

class ClipItemObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var url: URL?
    @Persisted var clipId: UUID
    @Persisted var clipIndex: Int = 0
    @Persisted var imageId: UUID
    @Persisted var imageFileName: String = ""
    @Persisted var imageUrl: URL?
    @Persisted var imageHeight: Double = 0
    @Persisted var imageWidth: Double = 0
    @Persisted var imageDataSize: Int = 0
    @Persisted var registeredAt = Date()
    @Persisted var updatedAt = Date()
}

extension ClipItemRecipe {
    static func make(by managedObject: ClipItemObject) -> ClipItemRecipe {
        return .init(id: managedObject.id,
                     url: managedObject.url,
                     clipId: managedObject.clipId,
                     clipIndex: managedObject.clipIndex,
                     imageId: managedObject.imageId,
                     imageFileName: managedObject.imageFileName,
                     imageUrl: managedObject.imageUrl,
                     imageSize: ImageSize(height: managedObject.imageHeight,
                                          width: managedObject.imageWidth),
                     imageDataSize: managedObject.imageDataSize,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}
