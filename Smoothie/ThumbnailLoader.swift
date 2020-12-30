//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol ThumbnailLoaderObserver: AnyObject {
    func didStartAsyncLoading(_ loader: ThumbnailLoader, request: ThumbnailRequest)
    func didFinishLoad(_ loader: ThumbnailLoader, request: ThumbnailRequest, result: ThumbnailLoadResult)
}

public class ThumbnailLoader {
    // MARK: - Properties

    private let pipeline: ThumbnailLoadPipeline
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    public init(pipeline: ThumbnailLoadPipeline) {
        self.pipeline = pipeline
    }

    // MARK: - Methods

    public func load(request: ThumbnailRequest, observer: ThumbnailLoaderObserver?) {
        if let cachedImage = pipeline.readCacheIfExists(for: request) {
            observer?.didFinishLoad(self, request: request, result: .loaded(cachedImage))
        } else {
            observer?.didStartAsyncLoading(self, request: request)
            pipeline.load(for: request)
                .map { ThumbnailLoadResult(loadResult: $0) }
                .receive(on: DispatchQueue.main)
                .sink { [weak self, weak observer] result in
                    guard let self = self else { return }
                    observer?.didFinishLoad(self, request: request, result: result)
                }
                .store(in: &self.cancellableBag)
        }
    }

    public func prefetch(for request: ThumbnailRequest) {
        pipeline.load(for: request)
            .sink { _ in }
            .store(in: &self.cancellableBag)
    }
}
