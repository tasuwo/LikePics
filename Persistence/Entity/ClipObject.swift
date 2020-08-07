//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class ClipObject: Object {
    @objc dynamic var url: String = ""
    @objc dynamic var image: Data?

    override static func primaryKey() -> String? {
        return "url"
    }
}

extension Clip: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: ClipObject) -> Clip {
        let image: UIImage? = {
            guard let data = managedObject.image else { return nil }
            return UIImage(data: data)
        }()
        return .init(url: URL(string: managedObject.url)!, image: image)
    }

    func asManagedObject() -> ClipObject {
        let obj = ClipObject()
        obj.url = self.url.absoluteString
        // TODO: 保存フォーマットを考える
        obj.image = self.image?.pngData()
        return obj
    }
}
