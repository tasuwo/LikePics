//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var descriptionText: String?
    let items = List<ClipItemObject>()
    let tags = List<TagObject>()
    @objc dynamic var isHidden: Bool = false
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Domain.Clip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipObject) -> Domain.Clip {
        let items = Array(managedObject.items.map { Domain.ClipItem.make(by: $0) })

        return .init(id: managedObject.id,
                     description: managedObject.descriptionText,
                     items: items,
                     tags: managedObject.tags.map { Domain.Tag.make(by: $0) },
                     isHidden: managedObject.isHidden,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}
