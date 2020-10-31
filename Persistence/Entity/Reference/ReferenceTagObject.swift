//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ReferenceTagObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    let clips = LinkingObjects(fromType: ReferenceClipObject.self, property: "tags")
    @objc dynamic var isDirty: Bool = false

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension ReferenceTag: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ReferenceTagObject) -> ReferenceTag {
        return .init(id: managedObject.id,
                     name: managedObject.name,
                     isDirty: managedObject.isDirty)
    }
}
