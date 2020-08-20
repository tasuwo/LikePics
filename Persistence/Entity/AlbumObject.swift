//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class AlbumObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    let clips = List<ClipObject>()
    @objc dynamic var registeredAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Album: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: AlbumObject) -> Album {
        let clips = Array(managedObject.clips.map { Clip.make(by: $0) })
        return .init(id: managedObject.id,
                     title: managedObject.title,
                     clips: clips,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }

    func asManagedObject() -> AlbumObject {
        let obj = AlbumObject()
        obj.id = self.id
        obj.title = self.title
        self.clips.forEach {
            obj.clips.append($0.asManagedObject())
        }
        obj.registeredAt = self.registeredDate
        obj.updatedAt = self.updatedDate
        return obj
    }
}
