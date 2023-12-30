//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import AsyncAlgorithms
import Combine
import SwiftUI

@available(iOS 17, macOS 14, *)
enum LazyImageLoadResult {
    case image(Image?)
}

@available(iOS 17, macOS 14, *)
public struct LazyImageCacheInfo: Equatable {
    public var key: String
    public var originalImageSize: CGSize

    public init(key: String, originalImageSize: CGSize) {
        self.key = key
        self.originalImageSize = originalImageSize
    }
}

@available(iOS 17, macOS 14, *)
final class LazyImageLoader: ObservableObject {
    struct Context {
        var data: () async -> Data?
        var cacheInfo: LazyImageCacheInfo
        var displayScale: CGFloat
        var imageProcessingQueue: ImageProcessingQueue
    }

    @Published var result: LazyImageLoadResult?

    var context: Context?

    private var cancellable: ImageLoadTaskCancellable?

    private let frameSizes: AsyncStream<CGSize>
    private let frameSizeContinuation: AsyncStream<CGSize>.Continuation
    private var frameSizeObservation: Task<Void, Never>?

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: CGSize.self)
        self.frameSizes = stream
        self.frameSizeContinuation = continuation

        frameSizeObservation = Task { [weak self, stream] in
            for await frameSize in stream.debounce(for: .seconds(1)) {
                await self?.load(thumbnailSize: frameSize)
            }
        }
    }

    deinit {
        cancellable?.cancel()
        frameSizeObservation?.cancel()
    }

    @MainActor
    func load(thumbnailSize: CGSize) {
        guard thumbnailSize != .zero, let context, !context.cacheInfo.key.isEmpty else {
            return
        }

        cancel()

        let request = ImageRequest(resize: .init(size: thumbnailSize, scale: context.displayScale), cacheKey: context.cacheInfo.key, diskCacheInvalidate: { [context, thumbnailSize] pixelSize in
            return ThumbnailInvalidationChecker.shouldInvalidateDiskCache(originalImageSizeInPoint: context.cacheInfo.originalImageSize,
                                                                          thumbnailSizeInPoint: thumbnailSize,
                                                                          diskCacheSizeInPixel: pixelSize,
                                                                          displayScale: context.displayScale)
        }, context.data)
        cancellable = context.imageProcessingQueue.loadImage(request) { [context, thumbnailSize, weak self] response in
            if let response {
                guard context.cacheInfo.key == self?.context?.cacheInfo.key else { return }

                if response.source == .memoryCache {
                    if ThumbnailInvalidationChecker.shouldInvalidateMemoryCache(originalImageSizeInPoint: context.cacheInfo.originalImageSize,
                                                                                thumbnailSizeInPoint: thumbnailSize,
                                                                                memoryCacheSizeInPixel: .init(width: response.image.size.width,
                                                                                                              height: response.image.size.height),
                                                                                displayScale: context.displayScale)
                    {
                        context.imageProcessingQueue.config.memoryCache.remove(forKey: context.cacheInfo.key)
                        self?.load(thumbnailSize: thumbnailSize)
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

    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }

    func onChangeFrame(_ frame: CGSize) {
        frameSizeContinuation.yield(frame)
    }
}

@available(iOS 17, macOS 14, *)
public struct LazyImage<Content>: View where Content: View {
    @StateObject private var loader = LazyImageLoader()

    @ViewBuilder private let content: (LazyImageLoadResult?) -> Content

    @Environment(\.displayScale) var displayScale
    @Environment(\.imageProcessingQueue) var imageProcessingQueue
    @Environment(\.lazyImageCacheInfo) var cacheInfo

    private let data: () async -> Data?

    public init<C, P>(data: @escaping () async -> Data?,
                      @ViewBuilder content: @escaping (Image?) -> C,
                      @ViewBuilder placeholder: @escaping () -> P) where C: View, P: View, Content == _ConditionalContent<C, P>
    {
        self.data = data
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
                    loader.context = context()
                    loader.load(thumbnailSize: geometry.size)
                }
                .onDisappear {
                    loader.cancel()
                }
                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
                .onChange(of: geometry.size) { oldValue, newValue in
                    loader.onChangeFrame(newValue)
                }
                .onChange(of: displayScale) { _, newValue in
                    loader.context = context()
                    loader.load(thumbnailSize: geometry.size)
                }
                .onChange(of: cacheInfo) { _, newValue in
                    loader.context = context()
                    loader.load(thumbnailSize: geometry.size)
                }
        }
    }

    private func context() -> LazyImageLoader.Context {
        return .init(data: data,
                     cacheInfo: cacheInfo,
                     displayScale: displayScale,
                     imageProcessingQueue: imageProcessingQueue)
    }
}

@available(iOS 17, macOS 14, *)
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

@available(iOS 17, macOS 14, *)
private struct LazyImageCacheInfoKey: EnvironmentKey {
    static let defaultValue = LazyImageCacheInfo(key: "", originalImageSize: .zero)
}

@available(iOS 17, macOS 14, *)
public extension EnvironmentValues {
    var lazyImageCacheInfo: LazyImageCacheInfo {
        get { self[LazyImageCacheInfoKey.self] }
        set { self[LazyImageCacheInfoKey.self] = newValue }
    }
}
