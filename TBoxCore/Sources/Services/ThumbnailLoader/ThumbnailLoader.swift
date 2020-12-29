//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import UIKit

public protocol ThumbnailLoaderProtocol {
    func load(_ source: ImageSource, as pointSize: CGSize, scale: CGFloat) -> Future<UIImage?, Never>
}

public class ThumbnailLoader {
    private let cache = NSCache<NSString, AnyObject>()
    private var cancellableBag = Set<AnyCancellable>()
}

extension ThumbnailLoader: ThumbnailLoaderProtocol {
    // MARK: - ThumbnailLoaderProtocol

    public func load(_ source: ImageSource, as pointSize: CGSize, scale: CGFloat) -> Future<UIImage?, Never> {
        switch source.value {
        case let .rawData(data):
            return Future { promise in
                if let cachedImage = self.cache.object(forKey: source.identifier.uuidString as NSString) as? UIImage {
                    promise(.success(cachedImage))
                    return
                }

                guard let image = ImageUtility.downsampling(data, to: pointSize, scale: scale) else {
                    promise(.success(nil))
                    return
                }

                self.cache.setObject(image, forKey: source.identifier.uuidString as NSString)

                promise(.success(image))
            }

        case let .urlSet(urlSet):
            return Future { [weak self] promise in
                guard let self = self else {
                    promise(.success(nil))
                    return
                }

                if let cachedImage = self.cache.object(forKey: urlSet.url.absoluteString as NSString) as? UIImage {
                    promise(.success(cachedImage))
                    return
                }

                URLSession.shared
                    .dataTaskPublisher(for: urlSet.url)
                    .map { ImageUtility.downsampling($0.data, to: pointSize, scale: scale) }
                    .catch { _ in Just(nil) }
                    .sink { image in
                        if let image = image {
                            self.cache.setObject(image, forKey: urlSet.url.absoluteString as NSString)
                        }
                        promise(.success(image))
                    }
                    .store(in: &self.cancellableBag)
            }
        }
    }
}
