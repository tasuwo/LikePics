//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ReferenceTagObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var isHidden: Bool = false
    @objc dynamic var isDirty: Bool = false

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension ReferenceTag: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ReferenceTagObject) -> ReferenceTag {
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!,
                     name: managedObject.name,
                     isHidden: managedObject.isHidden,
                     isDirty: managedObject.isDirty)
    }
}
