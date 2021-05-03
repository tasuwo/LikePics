//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

private struct ThumbnailRequestContext {
    let request: ThumbnailRequest
    weak var observer: ThumbnailLoadObserver?
}

class ThumbnailRequestPool {
    typealias RequestId = String

    let thumbnailId: String

    private var pool: [RequestId: ThumbnailRequestContext] = [:]
    private let lock = NSLock()

    weak var delegate: ThumbnailRequestPoolObserver?
    weak var ongoingOperation: Operation?

    // MARK: - Lifecycle

    init(thumbnailId: String) {
        self.thumbnailId = thumbnailId
    }

    // MARK: - Methods

    func append(_ request: ThumbnailRequest, with observer: ThumbnailLoadObserver?) {
        assert(request.thumbnailInfo.id == thumbnailId)

        lock.lock(); defer { lock.unlock() }

        pool[request.requestId] = ThumbnailRequestContext(request: request, observer: observer)
    }

    func didLoad(thumbnail: UIImage?) {
        lock.lock(); defer { lock.unlock() }

        if let image = thumbnail {
            pool.forEach { $1.observer?.didSuccessToLoad($1.request, image: image) }
        } else {
            pool.forEach { $1.observer?.didFailedToLoad($1.request) }
        }

        pool = [:]

        delegate?.didComplete(self)
    }

    func release(requestHaving requestId: RequestId) -> Bool {
        lock.lock(); defer { lock.unlock() }

        guard pool.keys.contains(requestId) else {
            return pool.isEmpty
        }

        pool.removeValue(forKey: requestId)

        return pool.isEmpty
    }

    func cancel(requestHaving requestId: RequestId) {
        lock.lock(); defer { lock.unlock() }

        guard pool.keys.contains(requestId) else { return }
        pool.removeValue(forKey: requestId)

        if pool.isEmpty {
            ongoingOperation?.cancel()
            delegate?.didComplete(self)
        }
    }
}
