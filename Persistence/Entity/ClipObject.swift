//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var url: String = ""
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
        return .init(id: managedObject.id,
                     // swiftlint:disable:next force_unwrapping
                     url: URL(string: managedObject.url)!,
                     description: managedObject.descriptionText,
                     items: items,
                     tags: managedObject.tags.map { Tag.make(by: $0) },
                     isHidden: managedObject.isHidden,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }

    func asManagedObject() -> ClipObject {
        let obj = ClipObject()
        obj.id = self.id
        obj.url = self.url.absoluteString
        obj.descriptionText = self.description
        self.items.forEach {
            obj.items.append($0.asManagedObject())
        }
        if !self.tags.isEmpty {
            fatalError("Unsupported to generate managed object for clips containing tag")
        }
        obj.isHidden = self.isHidden
        obj.registeredAt = self.registeredDate
        obj.updatedAt = self.updatedDate
        return obj
    }
}
