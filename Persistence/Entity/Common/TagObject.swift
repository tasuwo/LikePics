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
        // TODO: Realmオブジェクト定義を削除する
        // swiftlint:disable:next force_unwrapping
        return .init(id: UUID(uuidString: managedObject.id)!, name: managedObject.name, isHidden: false)
    }
}

extension Persistence.Tag {
    func map(to type: Domain.Tag.Type) -> Domain.Tag? {
        guard let id = self.id, let name = self.name else { return nil }
        return Domain.Tag(id: id,
                          name: name,
                          isHidden: self.isHidden,
                          clipCount: Int(self.clipCount))
    }
}
