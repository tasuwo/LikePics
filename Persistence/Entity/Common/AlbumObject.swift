//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class AlbumObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    let clips = List<ClipObject>()
    @objc dynamic var registeredAt = Date()
    @objc dynamic var updatedAt = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Domain.Album: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: AlbumObject) -> Domain.Album {
        let clips = Array(managedObject.clips.map { Domain.Clip.make(by: $0) })
        return .init(id: managedObject.id,
                     title: managedObject.title,
                     clips: clips,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}

extension Persistence.Album {
    func map(to: Domain.Album.Type) -> Domain.Album? {
        guard let id = self.id?.uuidString,
            let title = self.title,
            let createdDate = self.createdDate,
            let updateDate = self.updatedDate
        else {
            return nil
        }

        let clips = self.clips?
            .compactMap { $0 as? Persistence.Clip }
            .enumerated()
            .compactMap { $1.map(to: Domain.Clip.self) } ?? []

        return Domain.Album(id: id,
                            title: title,
                            clips: clips,
                            registeredDate: createdDate,
                            updatedDate: updateDate)
    }
}