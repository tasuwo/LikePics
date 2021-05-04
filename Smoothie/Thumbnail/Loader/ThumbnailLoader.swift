//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ThumbnailLoaderProtocol: AnyObject {
    func load(_ request: ThumbnailRequest, observer: ThumbnailLoadObserver?)
    func prefetch(_ request: ThumbnailRequest, observer: ThumbnailPrefetchObserver?)
    func cancel(_ request: ThumbnailRequest)
    func invalidateCache(having key: String)
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
        observer?.didStartLoading(request)
        queue.load(request, observer: observer)
    }

    public func prefetch(_ request: ThumbnailRequest, observer: ThumbnailPrefetchObserver?) {
        queue.prefetch(request, observer: observer)
    }

    public func cancel(_ request: ThumbnailRequest) {
        queue.cancel(request)
    }

    public func invalidateCache(having key: String) {
        queue.invalidateCache(having: key)
    }
}
