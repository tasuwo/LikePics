//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreGraphics
import Domain
import Foundation
import ImageIO
import Smoothie

class PreviewPrefetcher: PreviewPrefetchable {
    // MARK: - Properties

    let clip: CurrentValueSubject<Clip?, Never> = .init(nil)
    private let pipeline: Pipeline
    private let imageQueryService: ImageQueryServiceProtocol
    private let scale: CGFloat
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.PreviewPreLoader")
    private var subscriptions: Set<AnyCancellable> = .init()
    private var cancellables: [ImageRequestKey: ImageLoadTaskCancellable] = .init()

    // MARK: - Initializers

    init(pipeline: Pipeline, imageQueryService: ImageQueryServiceProtocol, scale: CGFloat) {
        self.pipeline = pipeline
        self.imageQueryService = imageQueryService
        self.scale = scale

        bind()
    }

    deinit {
        cancellables.values.forEach { $0.cancel() }
    }

    // MARK: - Methods

    private func bind() {
        clip
            .removeDuplicates()
            .receive(on: queue)
            .sink { [weak self] clip in self?.prefetch(clip) }
            .store(in: &subscriptions)
    }

    private func prefetch(_ clip: Clip?) {
        dispatchPrecondition(condition: .onQueue(queue))

        self.cancellables.values.forEach { $0.cancel() }
        self.cancellables = [:]

        guard let clip = clip,
              let primaryItem = clip.primaryItem,
              let data = pipeline.config.diskCache?["clip-collection-\(primaryItem.identity.uuidString)"],
              let pointSize = data.pointSize(scale: scale)
        else {
            return
        }

        self.cancellables = clip.items.reduce(into: [ImageRequestKey: ImageLoadTaskCancellable]()) { dict, item in
            let provider = ImageDataProvider(imageId: item.imageId,
                                             cacheKey: "clip-collection-\(item.identity.uuidString)",
                                             imageQueryService: imageQueryService)
            let request = ImageRequest(source: .provider(provider),
                                       resize: .init(size: pointSize, scale: scale))
            dict[ImageRequestKey(request)] = pipeline.preload(request) { [weak self] in
                self?.cancellables.removeValue(forKey: ImageRequestKey(request))
            }
        }
    }
}

private extension Data {
    func pointSize(scale: CGFloat) -> CGSize? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else {
            return nil
        }

        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
              let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
              let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            return nil
        }

        return CGSize(width: pixelWidth / scale, height: pixelHeight / scale)
    }
}
