//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import RealmSwift

final class ClippedImageObject: Object {
    @objc dynamic var key: String = ""
    @objc dynamic var clipUrl: String = ""
    @objc dynamic var imageUrl: String = ""
    @objc dynamic var image: Data = Data()

    override static func primaryKey() -> String? {
        return "key"
    }

    func makeKey() -> String {
        return "\(self.clipUrl)-\(self.imageUrl)"
    }
}
