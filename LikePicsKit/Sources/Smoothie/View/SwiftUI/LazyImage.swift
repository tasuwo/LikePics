//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import SwiftUI

enum LazyImageLoadResult {
    case image(Image?)
}

final class LazyImageLoader: ObservableObject {
    static var associatedKey = "ImageLoadTaskController.AssociatedKey"

    @Published var result: LazyImageLoadResult?

    private let originalSize: CGSize
    private let cacheKey: String
    private let data: () async -> Data?
    private var cancellable: ImageLoadTaskCancellable?

    var displayScale: CGFloat = 1
    var imageProcessingQueue: ImageProcessingQueue = .init()

    private let frameSize: CurrentValueSubject<CGSize, Never> = .init(.zero)
    private var frameSizeObservation: AnyCancellable?

    init(originalSize: CGSize, cacheKey: String, data: @escaping () async -> Data?) {
        self.originalSize = originalSize
        self.cacheKey = cacheKey
        self.data = data

        frameSizeObservation = frameSize
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] size in
                self?.load(with: size)
            }
    }

    deinit {
        cancellable?.cancel()
    }

    func load(with thumbnailSize: CGSize) {
        guard thumbnailSize != .zero else {
            return
        }

        cancel()

        let request = ImageRequest(resize: .init(size: thumbnailSize, scale: displayScale), cacheKey: cacheKey, diskCacheInvalidate: { [originalSize, thumbnailSize, displayScale] pixelSize in
            return ThumbnailInvalidationChecker.shouldInvalidateDiskCache(originalImageSizeInPoint: originalSize,
                                                                          thumbnailSizeInPoint: thumbnailSize,
                                                                          diskCacheSizeInPixel: pixelSize,
                                                                          displayScale: displayScale)
        }, data)
        cancellable = imageProcessingQueue.loadImage(request) { [cacheKey, originalSize, thumbnailSize, displayScale, weak self] response in
            DispatchQueue.main.async {
                if let response {
                    if response.source == .memoryCache {
                        if ThumbnailInvalidationChecker.shouldInvalidateMemoryCache(originalImageSizeInPoint: originalSize,
                                                                                    thumbnailSizeInPoint: thumbnailSize,
                                                                                    memoryCacheSizeInPixel: .init(width: response.image.size.width,
                                                                                                                  height: response.image.size.height),
                                                                                    displayScale: displayScale)
                        {
                            self?.imageProcessingQueue.config.memoryCache.remove(forKey: cacheKey)
                            self?.load(with: thumbnailSize)
                        }
                    }

                    #if canImport(UIKit)
                    self?.result = .image(Image(uiImage: response.image))
                    #endif
                    #if canImport(AppKit)
                    self?.result = .image(Image(nsImage: response.image))
                    #endif
                } else {
                    self?.result = nil
                }
            }
        }
    }

    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }

    func onChangeFrame(_ frame: CGSize) {
        frameSize.send(frame)
    }
}

public struct LazyImage<Content>: View where Content: View {
    @StateObject private var loader: LazyImageLoader
    @ViewBuilder private let content: (LazyImageLoadResult?) -> Content
    @Environment(\.displayScale) var displayScale
    @Environment(\.imageProcessingQueue) var imageProcessingQueue

    public init<C, P>(originalSize: CGSize,
                      cacheKey: String,
                      data: @escaping () async -> Data?,
                      @ViewBuilder content: @escaping (Image?) -> C,
                      @ViewBuilder placeholder: @escaping () -> P) where C: View, P: View, Content == _ConditionalContent<C, P>
    {
        self._loader = .init(wrappedValue: .init(originalSize: originalSize, cacheKey: cacheKey, data: data))
        self.content = { result in
            switch result {
            case let .image(image):
                return ViewBuilder.buildEither(first: content(image))

            case .none:
                return ViewBuilder.buildEither(second: placeholder())
            }
        }
    }

    public var body: some View {
        GeometryReader { geometry in
            content(loader.result)
                .onAppear {
                    loader.displayScale = displayScale
                    loader.imageProcessingQueue = imageProcessingQueue
                    loader.load(with: geometry.size)
                }
                .onDisappear {
                    loader.cancel()
                }
                .onChange(of: geometry.size) { oldValue, newValue in
                    loader.onChangeFrame(newValue)
                }
        }
    }
}

private enum ThumbnailInvalidationChecker {
    fileprivate static func shouldInvalidateDiskCache(originalImageSizeInPoint: CGSize,
                                                      thumbnailSizeInPoint: CGSize,
                                                      diskCacheSizeInPixel: CGSize,
                                                      displayScale: CGFloat) -> Bool
    {
        if originalImageSizeInPoint.width <= thumbnailSizeInPoint.width,
           originalImageSizeInPoint.height <= thumbnailSizeInPoint.height
        {
            return false
        }

        let thresholdInPoint: CGFloat = 10
        let widthDiff = thumbnailSizeInPoint.width - diskCacheSizeInPixel.width / displayScale
        let heightDiff = thumbnailSizeInPoint.height - diskCacheSizeInPixel.height / displayScale

        let result = widthDiff > thresholdInPoint || heightDiff > thresholdInPoint

        return result
    }

    fileprivate static func shouldInvalidateMemoryCache(originalImageSizeInPoint: CGSize,
                                                        thumbnailSizeInPoint: CGSize,
                                                        memoryCacheSizeInPixel: CGSize,
                                                        displayScale: CGFloat) -> Bool
    {
        if originalImageSizeInPoint.width <= thumbnailSizeInPoint.width,
           originalImageSizeInPoint.height <= thumbnailSizeInPoint.height
        {
            return false
        }

        let thresholdInPoint: CGFloat = 30
        let widthDiff = abs(thumbnailSizeInPoint.width - memoryCacheSizeInPixel.width / displayScale)
        let heightDiff = abs(thumbnailSizeInPoint.height - memoryCacheSizeInPixel.height / displayScale)

        let result = widthDiff > thresholdInPoint || heightDiff > thresholdInPoint

        return result
    }
}
