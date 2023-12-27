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
    @Published var frameSize: CGSize = .zero
    @Published var thumbnailSize: CGSize = .zero

    private let originalSize: CGSize
    private let cacheKey: String
    private let data: () async -> Data?
    private var cancellable: ImageLoadTaskCancellable?

    var displayScale: CGFloat = 1
    var imageProcessingQueue: ImageProcessingQueue = .init()

    private var frameSizeObservation: AnyCancellable?

    init(originalSize: CGSize, cacheKey: String, data: @escaping () async -> Data?) {
        self.originalSize = originalSize
        self.cacheKey = cacheKey
        self.data = data

        frameSizeObservation = $frameSize
            .debounce(for: 1.5, scheduler: RunLoop.main)
            .sink { [weak self] size in
                self?.thumbnailSize = size
                self?.load()
            }
    }

    deinit {
        cancellable?.cancel()
    }

    func load() {
        guard thumbnailSize != .zero else {
            return
        }

        cancel()

        let request = ImageRequest(resize: .init(size: thumbnailSize, scale: displayScale), cacheKey: cacheKey, cacheInvalidate: { [originalSize, thumbnailSize, displayScale] pixelSize in
            return ThumbnailInvalidationChecker.shouldInvalidate(originalImageSizeInPoint: originalSize,
                                                                 thumbnailSizeInPoint: thumbnailSize,
                                                                 diskCacheSizeInPixel: pixelSize,
                                                                 displayScale: displayScale)
        }, data)
        cancellable = imageProcessingQueue.loadImage(request) { [weak self] response in
            DispatchQueue.main.async {
                if let response {
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
        content(loader.result)
            .onAppear {
                loader.displayScale = displayScale
                loader.imageProcessingQueue = imageProcessingQueue
                loader.load()
            }
            .onDisappear {
                loader.cancel()
            }
            .background {
                GeometryReader {
                    Color.clear
                        .preference(key: _SizePreferenceKey.self, value: $0.size)
                }
            }
            .onPreferenceChange(_SizePreferenceKey.self) { size in
                if loader.thumbnailSize == .zero {
                    loader.thumbnailSize = size
                } else {
                    loader.frameSize = size
                }
            }
    }
}

private struct _SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

private enum ThumbnailInvalidationChecker {
    fileprivate static func shouldInvalidate(originalImageSizeInPoint: CGSize,
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
}
