//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public protocol ThumbnailLoaderProtocol {
    func load(from source: ImageSource) -> Future<UIImage?, Never>
}

public class ThumbnailLoader {
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.TBoxCore.ThumbnailLoader", qos: .userInteractive, attributes: .concurrent)
    private let cache = NSCache<NSString, NSData>()
    private var cancellableBag = Set<AnyCancellable>()
}

extension ThumbnailLoader: ThumbnailLoaderProtocol {
    // MARK: - ThumbnailLoaderProtocol

    public func load(from source: ImageSource) -> Future<UIImage?, Never> {
        switch source.value {
        case let .rawData(data):
            return Future { $0(.success(UIImage(data: data))) }

        case let .urlSet(urlSet):
            return Future { [weak self] promise in
                guard let self = self else {
                    promise(.success(nil))
                    return
                }

                if let cachedImage = self.cache.object(forKey: urlSet.url.absoluteString as NSString) as Data? {
                    promise(.success(UIImage(data: cachedImage)))
                    return
                }

                self.queue.async {
                    guard let size = source.resolveSize() else {
                        promise(.success(nil))
                        return
                    }

                    URLSession.shared
                        .dataTaskPublisher(for: urlSet.url)
                        .map { data, _ -> UIImage? in
                            let downsampleSize = ImageUtility.calcDownsamplingSize(forOriginalSize: size)
                            return ImageUtility.downsampledImage(data: data, to: downsampleSize)
                        }
                        .catch { _ in Just(nil) }
                        .sink { image in
                            if let data = image?.pngData() as NSData? {
                                self.cache.setObject(data, forKey: urlSet.url.absoluteString as NSString)
                            }
                            promise(.success(image))
                        }
                        .store(in: &self.cancellableBag)
                }
            }
        }
    }
}
