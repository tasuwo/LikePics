//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol ThumbnailRenderable {
    func load(request: ThumbnailLoadRequest?, into view: ThumbnailDisplayable)
    func prefetch(for request: ThumbnailLoadRequest)
}

public class ThumbnailRenderer {
    // MARK: - Properties

    private let thumbnailLoader: ThumbnailLoader
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    public init(thumbnailLoader: ThumbnailLoader) {
        self.thumbnailLoader = thumbnailLoader
    }
}

// MARK: - ThumbnailRenderable

extension ThumbnailRenderer: ThumbnailRenderable {
    public func load(request: ThumbnailLoadRequest?, into view: ThumbnailDisplayable) {
        guard let request = request else {
            view.set(.noImage)
            return
        }

        if let cachedImage = thumbnailLoader.readCacheIfExists(for: request) {
            view.set(.loaded(cachedImage))
        } else {
            view.startLoading()
            self.thumbnailLoader.load(for: request)
                .filter { _ in view.identifier == request.identifier }
                .map { ThumbnailLoadResult(loadResult: $0) }
                .receive(on: DispatchQueue.main)
                .sink { view.set($0) }
                .store(in: &self.cancellableBag)
        }
    }

    public func prefetch(for request: ThumbnailLoadRequest) {
        self.thumbnailLoader.load(for: request)
            .sink { _ in }
            .store(in: &self.cancellableBag)
    }
}
