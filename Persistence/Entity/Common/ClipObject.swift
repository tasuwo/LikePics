//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var id: String = ""
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

extension Domain.Clip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipObject) -> Domain.Clip {
        let items = Array(managedObject.items.map { Domain.ClipItem.make(by: $0) })
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!,
                     description: managedObject.descriptionText,
                     items: items,
                     tags: managedObject.tags.map { Domain.Tag.make(by: $0) },
                     isHidden: managedObject.isHidden,
                     registeredDate: managedObject.registeredAt,
                     updatedDate: managedObject.updatedAt)
    }
}

extension Persistence.Clip {
    func map(to type: Domain.Clip.Type) -> Domain.Clip? {
        guard let id = self.id,
            let createdDate = self.createdDate,
            let updatedDate = self.updatedDate
        else {
            return nil
        }

        let tags = self.tags?.allObjects
            .compactMap { $0 as? Persistence.Tag }
            .compactMap { $0.map(to: Domain.Tag.self) } ?? []

        let items = self.items?
            .compactMap { $0 as? Persistence.Item }
            .compactMap { $0.map(to: Domain.ClipItem.self) } ?? []

        return Domain.Clip(id: id,
                           description: self.descriptionText,
                           items: items,
                           tags: tags,
                           isHidden: self.isHidden,
                           registeredDate: createdDate,
                           updatedDate: updatedDate)
    }
}
