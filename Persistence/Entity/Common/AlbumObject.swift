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
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!,
                     title: managedObject.title,
                     clips: clips,
                     // TODO: Realmモデル定義を削除する
                     isHidden: false,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}

extension Persistence.Album {
    func map(to: Domain.Album.Type) -> Domain.Album? {
        guard let id = self.id,
            let title = self.title,
            let createdDate = self.createdDate,
            let updateDate = self.updatedDate
        else {
            return nil
        }

        let clips = self.items?
            .allObjects
            .compactMap { $0 as? AlbumItem }
            .sorted(by: { $0.index < $1.index })
            .compactMap { $0.clip }
            .compactMap { $0.map(to: Domain.Clip.self) } ?? []

        return Domain.Album(id: id,
                            title: title,
                            clips: clips,
                            isHidden: self.isHidden,
                            registeredDate: createdDate,
                            updatedDate: updateDate)
    }
}
