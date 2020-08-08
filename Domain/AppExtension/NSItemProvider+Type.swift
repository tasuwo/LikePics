//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import MobileCoreServices
import UIKit

public enum NSItemProviderResolutionError: Error {
    case invalidType
    case internalError
}

extension NSItemProvider {
    public var isUrl: Bool {
        return self.hasItemConformingToTypeIdentifier(kUTTypeURL as String)
    }

    public var isText: Bool {
        return self.hasItemConformingToTypeIdentifier(kUTTypeText as String)
    }

    public var isImage: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeImage as String)
    }

    public func resolveUrl(completion: @escaping (Result<URL, NSItemProviderResolutionError>) -> Void) {
        guard self.isUrl else {
            completion(.failure(.invalidType))
            return
        }
        self.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { item, error in
            guard let url = item as? URL else {
                completion(.failure(.invalidType))
                return
            }
            completion(.success(url))
        }
    }

    public func resolveText(completion: @escaping (Result<String, NSItemProviderResolutionError>) -> Void) {
        guard self.isText else {
            completion(.failure(.invalidType))
            return
        }
        self.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { item, error in
            guard let text = item as? String else {
                completion(.failure(.invalidType))
                return
            }
            completion(.success(text))
        }
    }

    public func resolveImage(completion: @escaping (Result<UIImage, NSItemProviderResolutionError>) -> Void) {
        if self.isImage {
            self.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { item, error in
                guard let imageUrl = item as? URL else {
                    completion(.failure(.invalidType))
                    return
                }
                guard let image = self.fetchImage(fromUrl: imageUrl) else {
                    completion(.failure(.internalError))
                    return
                }
                completion(.success(image))
            }
        } else if self.isUrl {
            self.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { item, error in
                guard let url = item as? URL else {
                    completion(.failure(.invalidType))
                    return
                }
                guard let image = self.fetchImage(fromUrl: url) else {
                    completion(.failure(.internalError))
                    return
                }
                completion(.success(image))
            }
        } else {
            completion(.failure(.invalidType))
        }
    }

    private func fetchImage(fromUrl url: URL) -> UIImage? {
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        return image
    }
}
