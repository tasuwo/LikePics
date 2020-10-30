//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class LightweightClipObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var url: String? = ""
    let tags = List<LightweightTagObject>()

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension LightweightClip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: LightweightClipObject) -> LightweightClip {
        let url: URL?
        if let urlString = managedObject.url {
            url = URL(string: urlString)
        } else {
            url = nil
        }

        return .init(id: managedObject.id,
                     url: url,
                     tags: managedObject.tags.map { LightweightTag.make(by: $0) })
    }
}
