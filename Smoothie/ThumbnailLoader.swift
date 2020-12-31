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
        if let cachedImage = pipeline.readCacheIfExists(for: request) {
            observer?.didSuccessToLoad(request, image: cachedImage)
        } else {
            observer?.didStartLoading(request)
            pipeline.load(for: request, observer: observer)
        }
    }

    public func prefetch(for request: ThumbnailRequest) {
        pipeline.load(for: request, observer: nil)
    }
}
