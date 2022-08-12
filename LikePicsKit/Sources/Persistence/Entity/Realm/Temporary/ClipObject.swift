//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

class ClipObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var descriptionText: String?
    @Persisted var items: List<ClipItemObject>
    @Persisted var tagIds: List<TagIdObject>
    @Persisted var albumIds: List<AlbumIdObject>
    @Persisted var isHidden = false
    @Persisted var dataSize: Int = 0
    @Persisted var registeredAt = Date()
    @Persisted var updatedAt = Date()
}

extension Domain.Clip {
    static func make(by managedObject: ClipObject) -> ClipRecipe {
        let items = Array(managedObject.items.map { ClipItemRecipe.make(by: $0) })
        return .init(id: managedObject.id,
                     description: managedObject.descriptionText,
                     items: items,
                     tagIds: managedObject.tagIds.compactMap({ $0.id }),
                     albumIds: managedObject.albumIds.compactMap({ $0.id }),
                     isHidden: managedObject.isHidden,
                     dataSize: managedObject.dataSize,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}
