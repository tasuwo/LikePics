//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var url: String? = ""
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

extension Clip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipObject) -> Clip {
        let items = Array(managedObject.items.map { ClipItem.make(by: $0) })

        let url: URL?
        if let urlString = managedObject.url {
            url = URL(string: urlString)
        } else {
            url = nil
        }

        return .init(id: managedObject.id,
                     url: url,
                     description: managedObject.descriptionText,
                     items: items,
                     tags: managedObject.tags.map { Tag.make(by: $0) },
                     isHidden: managedObject.isHidden,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}
