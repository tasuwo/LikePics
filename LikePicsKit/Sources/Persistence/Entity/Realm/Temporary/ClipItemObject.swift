//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

class ClipItemObject: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var url: URL?
    @Persisted var clipId: String = ""
    @Persisted var clipIndex: Int = 0
    @Persisted var imageId: String = ""
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
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!,
                     url: managedObject.url,
                     // swiftlint:disable:next force_unwrapping
                     clipId: UUID(uuidString: managedObject.clipId)!,
                     clipIndex: managedObject.clipIndex,
                     // swiftlint:disable:next force_unwrapping
                     imageId: UUID(uuidString: managedObject.imageId)!,
                     imageFileName: managedObject.imageFileName,
                     imageUrl: managedObject.imageUrl,
                     imageSize: ImageSize(height: managedObject.imageHeight,
                                          width: managedObject.imageWidth),
                     imageDataSize: managedObject.imageDataSize,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}
