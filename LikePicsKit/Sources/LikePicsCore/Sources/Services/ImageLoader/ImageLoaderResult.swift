//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ImageLoaderResult {
    let usedUrl: URL?
    let mimeType: String?
    let fileName: String?
    let data: Data
}
