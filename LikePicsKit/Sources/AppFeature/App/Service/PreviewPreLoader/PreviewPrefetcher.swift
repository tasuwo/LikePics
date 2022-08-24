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

    private let pipeline: Pipeline
    private let imageQueryService: ImageQueryServiceProtocol
    private let scale: CGFloat
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.PreviewPreLoader")

    // MARK: - Initializers

    init(pipeline: Pipeline, imageQueryService: ImageQueryServiceProtocol, scale: CGFloat) {
        self.pipeline = pipeline
        self.imageQueryService = imageQueryService
        self.scale = scale
    }
}

extension PreviewPrefetcher: PreviewPrefetchable {
    func prefetchPreview(for item: ClipItem) -> PreviewPrefetchCancellable {
        let provider = ImageDataProvider(imageId: item.imageId,
                                         cacheKey: "preview-\(item.identity.uuidString)",
                                         imageQueryService: imageQueryService)
        let request = ImageRequest(source: .provider(provider))
        // TODO: メモリ上にのみロードする
        let cancellable = pipeline.preload(request, completion: {})
        return Cancellable(cancellable)
    }
}
