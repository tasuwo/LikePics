//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Foundation

public struct ClipItemPartialRecipe {
    enum InitializeError: Error {
        case failedToResolveSize
    }

    let index: Int
    let url: URL?
    let data: Data
    let mimeType: String?
    let height: Double
    let width: Double
    private let _fileName: String?

    var fileName: String {
        // Note: タイトル無しの場合は空文字にする
        _fileName ?? ""
    }

    // MARK: - Lifecycle

    init(index: Int, result: ImageLoaderResult) throws {
        self.index = index
        self.url = result.usedUrl
        self.data = result.data
        self.mimeType = result.mimeType
        self._fileName = result.fileName

        guard let size = ImageUtility.resolveSize(for: result.data) else {
            throw InitializeError.failedToResolveSize
        }
        self.height = Double(size.height)
        self.width = Double(size.width)
    }
}
