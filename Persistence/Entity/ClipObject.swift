//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var url: String = ""
    let webImages = List<WebImageObject>()

    override static func primaryKey() -> String? {
        return "url"
    }
}

extension Clip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipObject) -> Clip {
        let items = Array(managedObject.webImages.map { ClipItem.make(by: $0) })
        return .init(url: URL(string: managedObject.url)!, description: nil, items: items)
    }

    func asManagedObject() -> ClipObject {
        let obj = ClipObject()
        obj.url = self.url.absoluteString
        self.items.forEach {
            obj.webImages.append($0.asManagedObject())
        }
        return obj
    }
}
