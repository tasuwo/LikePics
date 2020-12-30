//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public class ThumbnailLoader {
    public struct Configuration {
        public let memoryCache: MemoryCaching
        public let diskCache: DiskCaching?
        public let compressionRatio: Float

        public let dataLoadingQueue = OperationQueue()
        public let dataCachingQueue = OperationQueue()
        public let downsamplingQueue = OperationQueue()
        public let imageDecodingQueue = OperationQueue()
        public let imageEncodingQueue = OperationQueue()
        public let imageDecompressingQueue = OperationQueue()

        public init(memoryCache: MemoryCaching,
                    diskCache: DiskCaching,
                    compressionRatio: Float = 0.8)
        {
            self.memoryCache = memoryCache
            self.diskCache = diskCache
            self.compressionRatio = compressionRatio

            self.dataLoadingQueue.maxConcurrentOperationCount = 3
            self.dataCachingQueue.maxConcurrentOperationCount = 2
            self.downsamplingQueue.maxConcurrentOperationCount = 2
            self.imageDecodingQueue.maxConcurrentOperationCount = 1
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageDecompressingQueue.maxConcurrentOperationCount = 2
        }
    }

    private let config: Configuration
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.ThumbnailRenderer", target: .global(qos: .userInitiated))

    // MARK: - Lifecycle

    public init(config: Configuration) {
        self.config = config
    }

    // MARK: - Methods

    func readCacheIfExists(for request: ThumbnailLoadRequest) -> UIImage? {
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

    func load(for request: ThumbnailLoadRequest) -> Future<UIImage?, Never> {
        return Future { [weak self] promise in
            self?.queue.async {
                if let data = self?.config.memoryCache[request.cacheKey] {
                    self?.enqueueDecompressingOperation(for: request, data: data, promise: promise)
                } else {
                    self?.enqueueCheckCacheOperation(for: request, promise: promise)
                }
            }
        }
    }

    // MARK: Privates

    // MARK: Operations

    private func enqueueCheckCacheOperation(for request: ThumbnailLoadRequest, promise: @escaping Future<UIImage?, Never>.Promise) {
        let operation = BlockOperation { [weak self, promise] in
            guard let self = self else { return }

            let data = self.config.diskCache?[request.cacheKey]

            self.queue.async {
                if let data = data {
                    self.enqueueDecompressingOperation(for: request, data: data, promise: promise)
                } else {
                    self.enqueueDataLoadingOperation(for: request, promise: promise)
                }
            }
        }
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDataLoadingOperation(for request: ThumbnailLoadRequest, promise: @escaping Future<UIImage?, Never>.Promise) {
        let operation = BlockOperation { [weak self, promise] in
            guard let self = self else { return }

            let data = request.dataLoader.load()

            self.queue.async {
                if let data = data {
                    self.enqueueDownsamplingOperation(for: request, data: data, promise: promise)
                } else {
                    promise(.success(nil))
                }
            }
        }
        config.dataLoadingQueue.addOperation(operation)
    }

    private func enqueueDownsamplingOperation(for request: ThumbnailLoadRequest, data: Data, promise: @escaping Future<UIImage?, Never>.Promise) {
        let operation = BlockOperation { [weak self, promise] in
            guard let self = self else { return }

            let thumbnail = self.thumbnail(for: request, data: data)

            self.queue.async {
                if let thumbnail = thumbnail {
                    self.enqueueEncodingOperation(for: request, thumbnail: thumbnail, promise: promise)
                } else {
                    promise(.success(nil))
                }
            }
        }
        config.downsamplingQueue.addOperation(operation)
    }

    private func enqueueEncodingOperation(for request: ThumbnailLoadRequest, thumbnail: CGImage, promise: @escaping Future<UIImage?, Never>.Promise) {
        let operation = BlockOperation { [weak self, promise] in
            guard let self = self else { return }

            let encodedImage = self.encode(thumbnail, compressionRatio: self.config.compressionRatio)

            self.queue.async {
                if let encodedImage = encodedImage {
                    self.enqueueCachingOperation(for: request, data: encodedImage)
                    self.enqueueDecompressingOperation(for: request, data: encodedImage, promise: promise)
                } else {
                    promise(.success(nil))
                }
            }
        }
        config.imageEncodingQueue.addOperation(operation)
    }

    private func enqueueCachingOperation(for request: ThumbnailLoadRequest, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }
            self.config.diskCache?.store(data, forKey: request.cacheKey)
            self.config.memoryCache.insert(data, forKey: request.cacheKey)
        }
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDecompressingOperation(for request: ThumbnailLoadRequest, data: Data, promise: @escaping Future<UIImage?, Never>.Promise) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let image = self.decompress(data)

            self.queue.async {
                promise(.success(image))
            }
        }
        config.imageDecompressingQueue.addOperation(operation)
    }

    // MARK: Image Processing

    private func decompress(_ data: Data) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: true] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions),
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private func thumbnail(for request: ThumbnailLoadRequest, data: Data) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(request.size.width, request.size.height) * request.scale
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
