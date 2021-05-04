//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

private enum ThumbnailRequestContext {
    struct LoadContext {
        let request: ThumbnailRequest
        weak var observer: ThumbnailLoadObserver?
    }

    struct PrefetchContext {
        let request: ThumbnailRequest
        weak var observer: ThumbnailPrefetchObserver?
    }

    case load(LoadContext)
    case prefetch(PrefetchContext)

    var request: ThumbnailRequest {
        switch self {
        case let .load(context):
            return context.request

        case let .prefetch(context):
            return context.request
        }
    }

    var isPrefetch: Bool {
        switch self {
        case .prefetch:
            return true

        default:
            return false
        }
    }

    var loadObserver: ThumbnailLoadObserver? {
        guard case let .load(context) = self else { return nil }
        return context.observer
    }

    var prefetchObserver: ThumbnailPrefetchObserver? {
        guard case let .prefetch(context) = self else { return nil }
        return context.observer
    }
}

class ThumbnailRequestPool {
    typealias RequestId = String

    // TODO: サイズが異なるリクエストは別のPoolで扱う
    private let baseRequest: ThumbnailRequest
    private let lock = NSLock()
    private var pool: [RequestId: ThumbnailRequestContext]
    private var isPrefetched: Bool = false

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
        self.pool = [baseRequest.requestId: .load(.init(request: baseRequest, observer: observer))]
    }

    init(_ baseRequest: ThumbnailRequest, with observer: ThumbnailPrefetchObserver?) {
        self.baseRequest = baseRequest
        self.pool = [baseRequest.requestId: .prefetch(.init(request: baseRequest, observer: observer))]
    }

    // MARK: - Methods

    // MARK: Appending

    func appendLoadRequest(_ request: ThumbnailRequest, with observer: ThumbnailLoadObserver?) {
        assert(request.config.cacheKey == config.cacheKey)

        lock.lock(); defer { lock.unlock() }

        pool[request.requestId] = .load(.init(request: request, observer: observer))
    }

    func appendPrefetchRequest(_ request: ThumbnailRequest, with observer: ThumbnailPrefetchObserver?) {
        assert(request.config.cacheKey == config.cacheKey)

        lock.lock(); defer { lock.unlock() }

        guard !isPrefetched else { return }

        pool[request.requestId] = .prefetch(.init(request: request, observer: observer))
    }

    // MARK: Notify

    func didLoad(thumbnail: UIImage?) {
        lock.lock(); defer { lock.unlock() }

        if let image = thumbnail {
            pool.forEach { $1.loadObserver?.didSuccessToLoad($1.request, image: image) }
        } else {
            pool.forEach { $1.loadObserver?.didFailedToLoad($1.request) }
        }
        pool.forEach { $1.prefetchObserver?.didComplete($1.request) }

        pool = [:]

        delegate?.didComplete(self)
    }

    func releasePrefetches() {
        lock.lock(); defer { lock.unlock() }

        isPrefetched = true

        pool
            .filter { $0.value.isPrefetch }
            .forEach {
                $0.value.prefetchObserver?.didComplete($0.value.request)
                pool.removeValue(forKey: $0.key)
            }

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
