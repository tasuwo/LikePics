//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class LightweightTagObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    let clips = LinkingObjects(fromType: LightweightClipObject.self, property: "tags")

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension LightweightTag: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: LightweightTagObject) -> LightweightTag {
        return .init(id: managedObject.id,
                     name: managedObject.name)
    }
}
