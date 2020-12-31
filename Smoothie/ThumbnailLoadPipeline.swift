//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public class ThumbnailLoadPipeline {
    public struct Configuration {
        public var memoryCache: MemoryCaching = MemoryCache()
        public var diskCache: DiskCaching?
        public var compressionRatio: Float = 0.8
        public var dataLoader: OriginalImageLoader

        public let dataLoadingQueue = OperationQueue()
        public let dataCachingQueue = OperationQueue()
        public let downsamplingQueue = OperationQueue()
        public let imageDecodingQueue = OperationQueue()
        public let imageEncodingQueue = OperationQueue()
        public let imageDecompressingQueue = OperationQueue()

        public init(dataLoader: OriginalImageLoader) {
            self.dataLoader = dataLoader

            self.dataLoadingQueue.maxConcurrentOperationCount = 1
            self.dataCachingQueue.maxConcurrentOperationCount = 2
            self.downsamplingQueue.maxConcurrentOperationCount = 2
            self.imageDecodingQueue.maxConcurrentOperationCount = 1
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageDecompressingQueue.maxConcurrentOperationCount = 2
        }
    }

    private struct Context {
        let request: ThumbnailRequest
        let promise: Future<UIImage?, Never>.Promise
    }

    public let config: Configuration

    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.ThumbnailLoadPipeline", target: .global(qos: .userInitiated))

    // MARK: - Lifecycle

    public init(config: Configuration) {
        self.config = config
    }

    // MARK: - Methods

    func readCacheIfExists(for request: ThumbnailRequest) -> UIImage? {
        if let data = config.memoryCache[request.cacheKey],
            let image = decompress(data)
        {
            return image
        }

        if let data = config.diskCache?[request.cacheKey],
            let image = decompress(data)
        {
            config.memoryCache[request.cacheKey] = data
            return image
        }

        return nil
    }

    func load(for request: ThumbnailRequest) -> Future<UIImage?, Never> {
        return Future { [weak self] promise in
            self?.queue.async {
                if let data = self?.config.memoryCache[request.cacheKey] {
                    self?.enqueueDecompressingOperation(context: .init(request: request, promise: promise), data: data)
                } else {
                    self?.enqueueCheckCacheOperation(context: .init(request: request, promise: promise))
                }
            }
        }
    }
}

// MARK: Operations

extension ThumbnailLoadPipeline {
    private func enqueueCheckCacheOperation(context: Context) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let data = self.config.diskCache?[context.request.cacheKey]

            self.queue.async {
                if let data = data {
                    self.enqueueDecompressingOperation(context: context, data: data)
                } else {
                    self.enqueueDataLoadingOperation(context: context)
                }
            }
        }
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDataLoadingOperation(context: Context) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let data = self.config.dataLoader.loadData(with: context.request.originalDataRequest)

            self.queue.async {
                if let data = data {
                    self.enqueueDownsamplingOperation(context: context, data: data)
                } else {
                    context.promise(.success(nil))
                }
            }
        }
        config.dataLoadingQueue.addOperation(operation)
    }

    private func enqueueDownsamplingOperation(context: Context, data: Data) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let thumbnail = self.thumbnail(data: data,
                                           size: context.request.size,
                                           scale: context.request.scale)

            self.queue.async {
                if let thumbnail = thumbnail {
                    self.enqueueEncodingOperation(context: context, thumbnail: thumbnail)
                } else {
                    context.promise(.success(nil))
                }
            }
        }
        config.downsamplingQueue.addOperation(operation)
    }

    private func enqueueEncodingOperation(context: Context, thumbnail: CGImage) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let encodedImage = self.encode(thumbnail, compressionRatio: self.config.compressionRatio)

            self.queue.async {
                if let encodedImage = encodedImage {
                    self.enqueueCachingOperation(for: context.request, data: encodedImage)
                    self.enqueueDecompressingOperation(context: context, data: encodedImage)
                } else {
                    context.promise(.success(nil))
                }
            }
        }
        config.imageEncodingQueue.addOperation(operation)
    }

    private func enqueueCachingOperation(for request: ThumbnailRequest, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }
            self.config.diskCache?.store(data, forKey: request.cacheKey)
            self.config.memoryCache.insert(data, forKey: request.cacheKey)
        }
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDecompressingOperation(context: Context, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let image = self.decompress(data)

            self.queue.async {
                context.promise(.success(image))
            }
        }
        config.imageDecompressingQueue.addOperation(operation)
    }
}

// MARK: Image Processing

extension ThumbnailLoadPipeline {
    private func decompress(_ data: Data) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: true] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions),
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private func thumbnail(data: Data, size: CGSize, scale: CGFloat) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(size.width, size.height) * scale
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
            return nil
        }

        return downsampledImage
    }

    public func encode(_ image: CGImage, compressionRatio: Float) -> Data? {
        let type: ImageType = {
            return image.alphaInfo.hasAlphaChannel ? .png : .jpeg
        }()

        let mutableData = NSMutableData()
        let options: NSDictionary = [
            kCGImageDestinationLossyCompressionQuality: compressionRatio
        ]

        guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, type.uniformTypeIdentifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, options)
        CGImageDestinationFinalize(destination)

        return mutableData as Data
    }
}

private extension CGImageAlphaInfo {
    var hasAlphaChannel: Bool {
        switch self {
        case .none, .noneSkipLast, .noneSkipFirst:
            return false

        default:
            return true
        }
    }
}
