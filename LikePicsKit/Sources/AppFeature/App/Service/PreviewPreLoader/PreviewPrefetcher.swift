//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreGraphics
import Domain
import Foundation
import ImageIO
import Smoothie

class PreviewPrefetcher {
    class Cancellable: PreviewPrefetchCancellable {
        let cancellable: ImageLoadTaskCancellable

        init(_ cancellable: ImageLoadTaskCancellable) {
            self.cancellable = cancellable
        }

        deinit {
            cancel()
        }

        func cancel() {
            cancellable.cancel()
        }
    }

    // MARK: - Properties

    private let processingQueue: ImageProcessingQueue
    private let imageQueryService: ImageQueryServiceProtocol
    private var cancellables: [ImageRequestKey: PreviewPrefetchCancellable] = [:]

    // MARK: - Initializers

    init(processingQueue: ImageProcessingQueue, imageQueryService: ImageQueryServiceProtocol) {
        self.processingQueue = processingQueue
        self.imageQueryService = imageQueryService
    }

    deinit {
        cancellables.values.forEach { $0.cancel() }
    }

    // MARK: - Methods

    @discardableResult
    private func prefetch(for item: ClipItem, needsRetainCancellable: Bool) -> PreviewPrefetchCancellable {
        var request = ImageRequest(cacheKey: "preview-\(item.identity.uuidString)") { [imageQueryService, item] in
            try? imageQueryService.read(having: item.imageId)
        }
        request.ignoreDiskCaching = true

        let cancellable = processingQueue.loadImage(request) { [weak self] in
            self?.cancellables.removeValue(forKey: ImageRequestKey(request))
        }
        let previewCancellable = Cancellable(cancellable)

        if needsRetainCancellable {
            cancellables[ImageRequestKey(request)] = previewCancellable
        }

        return previewCancellable
    }
}

extension PreviewPrefetcher: PreviewPrefetchable {
    func prefetchPreview(for item: ClipItem) -> PreviewPrefetchCancellable {
        prefetch(for: item, needsRetainCancellable: false)
    }

    func detachedPrefetchPreview(for item: ClipItem) {
        prefetch(for: item, needsRetainCancellable: true)
    }
}
