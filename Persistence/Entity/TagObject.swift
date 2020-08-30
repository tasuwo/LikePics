//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class TagObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    let clips = LinkingObjects(fromType: ClipObject.self, property: "tags")

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Tag: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: TagObject) -> Tag {
        return .init(id: managedObject.id, name: managedObject.name)
    }

    func asManagedObject() -> TagObject {
        let obj = TagObject()
        obj.id = self.id
        obj.name = self.name
        return obj
    }
}
