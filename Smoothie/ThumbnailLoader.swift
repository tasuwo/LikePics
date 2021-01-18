//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ThumbnailLoadObserver: AnyObject {
    func didStartLoading(_ request: ThumbnailRequest)
    func didFailedToLoad(_ request: ThumbnailRequest)
    func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage)
}

public class ThumbnailLoader {
    // MARK: - Properties

    private let pipeline: ThumbnailLoadPipeline

    // MARK: - Lifecycle

    public init(pipeline: ThumbnailLoadPipeline) {
        self.pipeline = pipeline
    }

    // MARK: - Methods

    public func load(request: ThumbnailRequest, observer: ThumbnailLoadObserver?) {
        pipeline.readCacheIfExists(for: request) { [weak self] image in
            guard let self = self else {
                observer?.didFailedToLoad(request)
                return
            }
            if let image = image {
                observer?.didSuccessToLoad(request, image: image)
            } else {
                observer?.didStartLoading(request)
                self.pipeline.load(for: request, observer: observer)
            }
        }
    }

    public func cancel(_ request: ThumbnailRequest) {
        pipeline.cancel(request)
    }

    public func prefetch(for request: ThumbnailRequest) {
        pipeline.load(for: request, observer: nil)
    }
}
