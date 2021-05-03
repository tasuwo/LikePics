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

    // TODO: サイズが異なるリクエストは別のPoolで扱う
    private let baseRequest: ThumbnailRequest
    private let lock = NSLock()
    private var pool: [RequestId: ThumbnailRequestContext]

    var config: ThumbnailConfig { baseRequest.config }
    var imageRequest: OriginalImageRequest { baseRequest.imageRequest }

    var isEmpty: Bool {
        lock.lock(); defer { lock.unlock() }
        return pool.isEmpty
    }

    weak var delegate: ThumbnailRequestPoolObserver?
    weak var ongoingOperation: Operation?

    // MARK: - Lifecycle

    init(_ baseRequest: ThumbnailRequest, with observer: ThumbnailLoadObserver?) {
        self.baseRequest = baseRequest
        self.pool = [baseRequest.requestId: ThumbnailRequestContext(request: baseRequest, observer: observer)]
    }

    // MARK: - Methods

    func append(_ request: ThumbnailRequest, with observer: ThumbnailLoadObserver?) {
        assert(request.config.cacheKey == config.cacheKey)

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

    func releasePrefetches() {
        lock.lock(); defer { lock.unlock() }

        pool
            .filter { $0.value.request.isPrefetch }
            .map { $0.key }
            .forEach { pool.removeValue(forKey: $0) }

        if pool.isEmpty {
            ongoingOperation?.cancel()
            delegate?.didComplete(self)
        }
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
