//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var descriptionText: String?
    let items = List<ClipItemObject>()
    let tagIds = List<TagIdObject>()
    @objc dynamic var isHidden = false
    @objc dynamic var dataSize: Int = 0
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Domain.Clip {
    static func make(by managedObject: ClipObject) -> ClipRecipe {
        let items = Array(managedObject.items.map { ClipItemRecipe.make(by: $0) })
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!,
                     description: managedObject.descriptionText,
                     items: items,
                     tagIds: managedObject.tagIds.compactMap({ UUID(uuidString: $0.id) }),
                     isHidden: managedObject.isHidden,
                     dataSize: managedObject.dataSize,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}
