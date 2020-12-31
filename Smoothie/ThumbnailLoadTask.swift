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

    private var requests: [RequestId: RequestContext] = [:]

    weak var delegate: ThumbnailLoadTaskDelegate?
    weak var dependentOperation: Operation?

    // MARK: - Lifecycle

    init(thumbnailId: String) {
        self.thumbnailId = thumbnailId
    }

    // MARK: - Methods

    func append(_ request: ThumbnailRequest, observer: ThumbnailLoadObserver?) {
        self.requests[request.requestId] = RequestContext(request: request, observer: observer)
    }

    func didLoad(image: UIImage?) {
        if let image = image {
            self.requests.forEach { $1.observer?.didSuccessToLoad($1.request, image: image) }
        } else {
            self.requests.forEach { $1.observer?.didFailedToLoad($1.request) }
        }
        self.requests = [:]
        self.delegate?.didComplete(self)
    }

    func finish(requestId: RequestId) -> Bool {
        guard self.requests.keys.contains(requestId) else {
            return self.requests.isEmpty
        }
        self.requests.removeValue(forKey: requestId)
        return self.requests.isEmpty
    }

    func cancel(requestId: RequestId) {
        guard self.requests.keys.contains(requestId) else { return }
        self.requests.removeValue(forKey: requestId)
        if self.requests.isEmpty {
            self.dependentOperation?.cancel()
            self.delegate?.didComplete(self)
        }
    }
}
