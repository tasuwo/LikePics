//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import SwiftUI

enum LazyImageLoadResult {
    case image(Image?)
}

final class LazyImageModel: ObservableObject {
    static var associatedKey = "ImageLoadTaskController.AssociatedKey"

    @Published var result: LazyImageLoadResult?
    private var cancellable: ImageLoadTaskCancellable?

    deinit {
        self.cancellable?.cancel()
    }

    func update(originalSize: CGSize,
                cacheKey: String,
                thumbnailSize: CGSize,
                displayScale: CGFloat,
                processingQueue: ImageProcessingQueue,
                data: @escaping () async -> Data?)
    {
        guard thumbnailSize != .zero else {
            return
        }

        cancellable?.cancel()
        cancellable = nil

        let request = ImageRequest(resize: .init(size: thumbnailSize, scale: displayScale), cacheKey: cacheKey, cacheInvalidate: { pixelSize in
            return ThumbnailInvalidationChecker.shouldInvalidate(originalImageSizeInPoint: originalSize,
                                                                 thumbnailSizeInPoint: thumbnailSize,
                                                                 diskCacheSizeInPixel: pixelSize,
                                                                 displayScale: displayScale)
        }, data)
        cancellable = processingQueue.loadImage(request) { [weak self] response in
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
    @StateObject private var model = LazyImageModel()
    @ViewBuilder private let content: (LazyImageLoadResult?) -> Content
    @Environment(\.displayScale) var displayScale
    @Environment(\.imageProcessingQueue) var imageProcessingQueue

    private let originalSize: CGSize
    private let cacheKey: String
    private let data: () async -> Data?

    public init<C, P>(originalSize: CGSize,
                      cacheKey: String,
                      data: @escaping () async -> Data?,
                      @ViewBuilder content: @escaping (Image?) -> C,
                      @ViewBuilder placeholder: @escaping () -> P) where C: View, P: View, Content == _ConditionalContent<C, P>
    {
        self.originalSize = originalSize
        self.cacheKey = cacheKey
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
            content(model.result)
                .onAppear {
                    model.update(originalSize: originalSize,
                                 cacheKey: cacheKey,
                                 thumbnailSize: geometry.frame(in: .local).size,
                                 displayScale: displayScale,
                                 processingQueue: imageProcessingQueue,
                                 data: data)
                }
                .onDisappear {
                    model.cancel()
                }
                .position(.init(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY))
        }
    }
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

        let thresholdInPoint: CGFloat = 0
        let widthDiff = thumbnailSizeInPoint.width - diskCacheSizeInPixel.width / displayScale
        let heightDiff = thumbnailSizeInPoint.height - diskCacheSizeInPixel.height / displayScale

        let result = widthDiff > thresholdInPoint || heightDiff > thresholdInPoint

        return result
    }
}
