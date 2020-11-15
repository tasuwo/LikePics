//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ReferenceClipObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var descriptionText: String?
    let tags = List<ReferenceTagObject>()
    @objc dynamic var isHidden: Bool = false
    @objc dynamic var registeredAt = Date()
    @objc dynamic var isDirty: Bool = false

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension ReferenceClip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ReferenceClipObject) -> ReferenceClip {
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!,
                     description: managedObject.descriptionText,
                     tags: managedObject.tags.map { ReferenceTag.make(by: $0) },
                     isHidden: managedObject.isHidden,
                     registeredDate: managedObject.registeredAt,
                     isDirty: managedObject.isDirty)
    }
}
