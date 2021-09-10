//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import LikePicsCore
import MobileCoreServices
import UIKit

class ImageProvider {
    private let underlyingProvider: NSItemProvider

    init(_ provider: NSItemProvider) {
        self.underlyingProvider = provider
    }
}

extension ImageProvider: LikePicsCore.ImageProvider {
    // MARK: - ImageProvider

    func load(_ completion: @escaping (Data?) -> Void) {
        underlyingProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { data, _ in
            if let data = data as? Data {
                completion(data)
            } else if let image = data as? UIImage {
                completion(image.pngData())
            } else if let url = data as? URL, let imageData = try? Data(contentsOf: url) {
                completion(imageData)
            } else {
                completion(nil)
            }
        }
    }
}
