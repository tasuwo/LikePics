//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ImageLoaderResult {
    public let usedUrl: URL?
    public let mimeType: String?
    public let fileName: String?
    public let data: Data
}
