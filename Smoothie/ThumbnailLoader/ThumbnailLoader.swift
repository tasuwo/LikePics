//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ThumbnailLoaderProtocol: AnyObject {
    func load(_ request: ThumbnailRequest, observer: ThumbnailLoadObserver?)
    func cancel(_ request: ThumbnailRequest)
    func prefetch(_ request: ThumbnailRequest)
}

public class ThumbnailLoader {
    // MARK: - Properties

    private let queue: ThumbnailLoadQueue

    // MARK: - Lifecycle

    public init(queue: ThumbnailLoadQueue) {
        self.queue = queue
    }
}

// MARK: - ThumbnailLoaderProtocol

extension ThumbnailLoader: ThumbnailLoaderProtocol {
    public func load(_ request: ThumbnailRequest, observer: ThumbnailLoadObserver?) {
        queue.readCacheIfExists(for: request) { [weak self] image in
            guard let self = self else {
                observer?.didFailedToLoad(request)
                return
            }
            if let image = image {
                observer?.didSuccessToLoad(request, image: image)
            } else {
                observer?.didStartLoading(request)
                self.queue.load(request, observer: observer)
            }
        }
    }

    public func cancel(_ request: ThumbnailRequest) {
        queue.cancel(request)
    }

    public func prefetch(_ request: ThumbnailRequest) {
        queue.load(request, observer: nil)
    }
}
