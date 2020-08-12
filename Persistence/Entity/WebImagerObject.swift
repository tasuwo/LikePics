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
        let url = URL(string: managedObject.url)!

        // FIXME:
        let thumbnailImageUrl: URL
        if url.host?.contains("twimg") == true {
            thumbnailImageUrl = {
                guard var components = URLComponents(string: url.absoluteString),
                    let queryItems = components.queryItems
                else {
                    return url
                }

                let newQueryItems: [URLQueryItem] = queryItems
                    .compactMap { queryItem in
                        guard queryItem.name == "name" else { return queryItem }
                        return URLQueryItem(name: "name", value: "small")
                    }

                components.queryItems = newQueryItems

                return components.url ?? url
            }()
        } else {
            thumbnailImageUrl = url
        }

        // TODO: Migration
        return .init(clipUrl: URL(string: managedObject.url)!,
                     clipIndex: 0,
                     thumbnailImageUrl: thumbnailImageUrl,
                     thumbnailSize: .zero,
                     largeImageUrl: url,
                     largeImageSize: .zero)
    }

    func asManagedObject() -> WebImageObject {
        let obj = WebImageObject()
        obj.url = self.largeImageUrl.absoluteString

        // TODO: 保存フォーマットを考える
        let data = try! Data(contentsOf: self.largeImageUrl)
        let image = UIImage(data: data)!
        obj.image = image.pngData()!
        return obj
    }
}
