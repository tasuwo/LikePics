//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeature
import ClipCreationFeatureCore
import UIKit
import UniformTypeIdentifiers

class ImageProvider {
    private let underlyingProvider: NSItemProvider

    init(_ provider: NSItemProvider) {
        self.underlyingProvider = provider
    }
}

extension ImageProvider: LazyImageData {
    // MARK: - ImageProvider

    func fileName() async -> String? {
        if let name = underlyingProvider.suggestedName {
            return name
        }

        if let url = try? await underlyingProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
            return url.lastPathComponent
        }

        if let url = try? await underlyingProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
            return url.lastPathComponent
        }

        if let text = try? await underlyingProvider.loadItem(forTypeIdentifier: UTType.text.identifier) as? String {
            return text
        }

        return nil
    }

    func resolveFilename(_ completion: @escaping (String?) -> Void) {
        if let name = underlyingProvider.suggestedName {
            completion(name)
        }
        underlyingProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [underlyingProvider] data, _ in
            guard let url = data as? URL else {
                underlyingProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, _ in
                    guard let url = data as? URL else {
                        underlyingProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, _ in
                            guard let text = data as? String else {
                                completion(nil)
                                return
                            }
                            completion(text)
                        }
                        return
                    }
                    completion(url.lastPathComponent)
                }
                return
            }
            completion(url.lastPathComponent)
        }
    }

    func get() async -> Data? {
        guard let data = try? await underlyingProvider.loadItem(forTypeIdentifier: UTType.image.identifier) else { return nil }
        if let data = data as? Data {
            return data
        } else if let image = data as? UIImage {
            return image.pngData()
        } else if let url = data as? URL, let imageData = try? Data(contentsOf: url) {
            return imageData
        } else {
            return nil
        }
    }

    func fetch(_ completion: @escaping (Data?) -> Void) {
        underlyingProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, _ in
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
