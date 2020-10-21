//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipItemDataSource {
    static let fallbackFileExtension = "jpeg"

    let index: Int
    let url: URL
    let data: Data
    let mimeType: String?
    let height: Double
    let width: Double

    var fileName: String {
        let ext: String = {
            if let mimeType = self.mimeType {
                return ImageExtensionResolver.resolveFileExtension(forMimeType: mimeType) ?? Self.fallbackFileExtension
            } else {
                return Self.fallbackFileExtension
            }
        }()
        let name = WebImageNameResolver.resolveFileName(from: self.url) ?? UUID().uuidString
        return "\(name).\(ext)"
    }
}
