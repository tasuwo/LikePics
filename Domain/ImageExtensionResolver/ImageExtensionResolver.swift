//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import MobileCoreServices

public enum ImageExtensionResolver {
    // TODO: テーブルを自前で管理しなくて済むようにする
    private static let table: [String: String] = [
        "image/bmp": "bmp",
        "image/gif": "gif",
        "image/jpeg": "jpeg",
        "image/png": "png",
        "image/tiff": "tiff"
    ]

    public static func resolveFileExtension(forMimeType mimeType: String) -> String? {
        return self.table[mimeType]
    }
}
