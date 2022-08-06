//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeature
import MobileCoreServices
import UIKit

class ImageProvider {
    private let underlyingProvider: NSItemProvider

    init(_ provider: NSItemProvider) {
        self.underlyingProvider = provider
    }
}

extension ImageProvider: ImageLazyLoadable {
    // MARK: - ImageProvider

    func resolveFilename(_ completion: @escaping (String?) -> Void) {
        if let name = underlyingProvider.suggestedName {
            completion(name)
        }
        underlyingProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { data, _ in
            guard let url = data as? URL else {
                completion(nil)
                return
            }
            completion(url.lastPathComponent)
        }
    }

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
