//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ThumbnailLoadTaskDelegate: AnyObject {
    func didComplete(_ task: ThumbnailLoadTask)
}

class ThumbnailLoadTask {
    typealias RequestId = String

    private class RequestContext {
        let request: ThumbnailRequest
        weak var observer: ThumbnailLoadObserver?

        init(request: ThumbnailRequest, observer: ThumbnailLoadObserver?) {
            self.request = request
            self.observer = observer
        }
    }

    let thumbnailId: String

    private var requestPool: [RequestId: RequestContext] = [:]

    weak var delegate: ThumbnailLoadTaskDelegate?
    weak var dependentOperation: Operation?

    // MARK: - Lifecycle

    init(thumbnailId: String) {
        self.thumbnailId = thumbnailId
    }

    // MARK: - Methods

    func append(_ request: ThumbnailRequest, observer: ThumbnailLoadObserver?) {
        self.requestPool[request.requestId] = RequestContext(request: request, observer: observer)
    }

    func didLoad(thumbnail: UIImage?) {
        if let image = thumbnail {
            self.requestPool.forEach { $1.observer?.didSuccessToLoad($1.request, image: image) }
        } else {
            self.requestPool.forEach { $1.observer?.didFailedToLoad($1.request) }
        }
        self.requestPool = [:]
        self.delegate?.didComplete(self)
    }

    func didFinish(requestHaving requestId: RequestId) -> Bool {
        guard self.requestPool.keys.contains(requestId) else {
            return self.requestPool.isEmpty
        }
        self.requestPool.removeValue(forKey: requestId)
        return self.requestPool.isEmpty
    }

    func didCancel(requestHaving requestId: RequestId) {
        guard self.requestPool.keys.contains(requestId) else { return }
        self.requestPool.removeValue(forKey: requestId)
        if self.requestPool.isEmpty {
            self.dependentOperation?.cancel()
            self.delegate?.didComplete(self)
        }
    }
}
