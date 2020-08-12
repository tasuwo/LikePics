//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

final class WebImageObject: Object {
    @objc dynamic var url: String = ""
    @objc dynamic var image: Data = Data()
}

extension ClipItem: Persistable {
    // MARK: - Persistable

    static func make(by managedObject: WebImageObject) -> ClipItem {
        let image = UIImage(data: managedObject.image)!
        // TODO: Migration
        return .init(clipUrl: URL(string: managedObject.url)!,
                     clipIndex: 0,
                     imageUrl: URL(string: managedObject.url)!,
                     thumbnailImage: image,
                     largeImage: image)
    }

    func asManagedObject() -> WebImageObject {
        let obj = WebImageObject()
        obj.url = self.imageUrl.absoluteString
        // TODO: 保存フォーマットを考える
        obj.image = self.largeImage.pngData()!
        return obj
    }
}
