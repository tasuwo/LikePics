//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ReferenceClipObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var url: String? = ""
    @objc dynamic var descriptionText: String?
    let tags = List<ReferenceTagObject>()
    @objc dynamic var isHidden: Bool = false
    @objc dynamic var registeredAt = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension ReferenceClip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ReferenceClipObject) -> ReferenceClip {
        let url: URL?
        if let urlString = managedObject.url {
            url = URL(string: urlString)
        } else {
            url = nil
        }

        return .init(id: managedObject.id,
                     url: url,
                     description: managedObject.descriptionText,
                     tags: managedObject.tags.map { ReferenceTag.make(by: $0) },
                     isHidden: managedObject.isHidden,
                     registeredDate: managedObject.registeredAt)
    }
}
