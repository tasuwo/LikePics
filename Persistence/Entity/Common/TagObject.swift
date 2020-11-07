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

extension Domain.Tag: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: TagObject) -> Domain.Tag {
        return .init(id: managedObject.id, name: managedObject.name)
    }
}
