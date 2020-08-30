//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var url: String = ""
    @objc dynamic var descriptionText: String?
    let items = List<ClipItemObject>()
    let tags = List<TagObject>()
    @objc dynamic var registeredAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()

    override static func primaryKey() -> String? {
        return "url"
    }
}

extension Clip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipObject) -> Clip {
        let items = Array(managedObject.items.map { ClipItem.make(by: $0) })
        return .init(url: URL(string: managedObject.url)!,
                     description: managedObject.descriptionText,
                     items: items,
                     tags: managedObject.tags.map { $0.name },
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }

    func asManagedObject() -> ClipObject {
        let obj = ClipObject()
        obj.url = self.url.absoluteString
        obj.descriptionText = self.description
        self.items.forEach {
            obj.items.append($0.asManagedObject())
        }
        if self.tags.count > 0 {
            // TODO: warn log
            fatalError()
        }
        obj.registeredAt = self.registeredDate
        obj.updatedAt = self.updatedDate
        return obj
    }
}
