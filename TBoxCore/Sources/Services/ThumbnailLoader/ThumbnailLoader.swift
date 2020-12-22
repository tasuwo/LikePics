//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public protocol ThumbnailLoaderProtocol {
    func load(from source: ImageSource) -> Future<UIImage?, Never>
}

public class ThumbnailLoader {
    private var cancellableBag = Set<AnyCancellable>()
}

extension ThumbnailLoader: ThumbnailLoaderProtocol {
    // MARK: - ThumbnailLoaderProtocol

    public func load(from source: ImageSource) -> Future<UIImage?, Never> {
        guard let size = source.resolveSize() else { return Future { $0(.success(nil)) } }

        switch source.value {
        case let .rawData(data):
            return Future { $0(.success(UIImage(data: data))) }

        case let .urlSet(urlSet):
            return Future { [weak self] promise in
                guard let self = self else {
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
                    .sink { promise(.success($0)) }
                    .store(in: &self.cancellableBag)
            }
        }
    }
}
