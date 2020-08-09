//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class WebImageObject: Object {
    @objc dynamic var url: String = ""
    @objc dynamic var image: Data = Data()
}

extension WebImage: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: WebImageObject) -> WebImage {
        let image = UIImage(data: managedObject.image)!
        return .init(url: URL(string: managedObject.url)!, image: image)
    }

    func asManagedObject() -> WebImageObject {
        let obj = WebImageObject()
        obj.url = self.url.absoluteString
        // TODO: 保存フォーマットを考える
        obj.image = self.image.pngData()!
        return obj
    }
}
