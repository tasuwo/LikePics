//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import os
import UIKit

public class ThumbnailLoadQueue {
    typealias CacheKey = String

    public struct Configuration {
        public var memoryCache: MemoryCaching = MemoryCache()
        public var diskCache: DiskCaching?
        public var compressionRatio: Float = 0.8
        public var originalImageLoader: OriginalImageLoader

        public let dataLoadingQueue = OperationQueue()
        public let dataCachingQueue = OperationQueue()
        public let downsamplingQueue = OperationQueue()
        public let imageEncodingQueue = OperationQueue()
        public let imageDecompressingQueue = OperationQueue()

        public init(originalImageLoader: OriginalImageLoader) {
            self.originalImageLoader = originalImageLoader

            self.dataLoadingQueue.maxConcurrentOperationCount = 1
            self.dataCachingQueue.maxConcurrentOperationCount = 3
            self.downsamplingQueue.maxConcurrentOperationCount = 2
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageDecompressingQueue.maxConcurrentOperationCount = 2
        }
    }

    public let config: Configuration

    private let logger = Logger()
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.ThumbnailLoadQueue", target: .global(qos: .userInitiated))

    private var requestPools: [CacheKey: ThumbnailRequestPool] = [:]

    // MARK: - Lifecycle

    public init(config: Configuration) {
        self.config = config
    }
}

// MARK: - Load/Cancel

extension ThumbnailLoadQueue {
    func load(_ request: ThumbnailRequest, observer: ThumbnailLoadObserver?) {
        queue.async { [weak self, weak observer] in
            guard let self = self else { return }

            if let pool = self.requestPools[request.config.cacheKey] {
                pool.appendLoadRequest(request, with: observer)
                return
            }

            let pool = ThumbnailRequestPool(request, with: observer)
            pool.delegate = self
            self.requestPools[request.config.cacheKey] = pool

            guard let image = self.config.memoryCache[request.config.cacheKey] else {
                self.enqueueCheckCacheOperation(pool)
                return
            }

            pool.releasePrefetches()
            if pool.isEmpty { return }

            pool.didLoad(thumbnail: image)
        }
    }

    func prefetch(_ request: ThumbnailRequest, observer: ThumbnailPrefetchObserver?) {
        queue.async { [weak self, weak observer] in
            guard let self = self else { return }

            if let pool = self.requestPools[request.config.cacheKey] {
                pool.appendPrefetchRequest(request, with: observer)
                return
            }

            let pool = ThumbnailRequestPool(request, with: observer)
            pool.delegate = self
            self.requestPools[request.config.cacheKey] = pool

            guard let image = self.config.memoryCache[request.config.cacheKey] else {
                self.enqueueCheckCacheOperation(pool)
                return
            }

            pool.releasePrefetches()
            if pool.isEmpty { return }

            pool.didLoad(thumbnail: image)
        }
    }

    func cancel(_ request: ThumbnailRequest) {
        queue.async { [weak self] in
            guard let self = self, let pool = self.requestPools[request.config.cacheKey] else { return }
            pool.cancel(requestHaving: request.requestId)
        }
    }

    func invalidateCache(having key: String) {
        queue.async {
            self.config.memoryCache.remove(forKey: key)
            self.config.diskCache?.remove(forKey: key)
        }
    }
}

// MARK: Operations

extension ThumbnailLoadQueue {
    private func enqueueCheckCacheOperation(_ pool: ThumbnailRequestPool) {
        let operation = BlockOperation { [weak self, pool] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Read Disk Cache")
            let data = self.config.diskCache?[pool.config.cacheKey]
            log.log(.end, name: "Read Disk Cache")

            self.queue.async {
                guard let data = data else {
                    self.enqueueDataLoadingOperation(pool)
                    return
                }

                self.enqueueDecompressingOperation(pool, data: data)
            }
        }
        pool.ongoingOperation = operation
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDataLoadingOperation(_ pool: ThumbnailRequestPool) {
        let operation = BlockOperation { [weak self, pool] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Load Original Data")
            let data = self.config.originalImageLoader.loadData(with: pool.imageRequest)
            log.log(.end, name: "Load Original Data")

            self.queue.async {
                if let data = data {
                    self.enqueueDownsamplingOperation(pool, data: data)
                } else {
                    pool.didLoad(thumbnail: nil)
                }
            }
        }
        pool.ongoingOperation = operation
        config.dataLoadingQueue.addOperation(operation)
    }

    private func enqueueDownsamplingOperation(_ pool: ThumbnailRequestPool, data: Data) {
        let operation = BlockOperation { [weak self, pool] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Downsample Data")
            let thumbnail = self.thumbnail(data: data,
                                           size: pool.config.size,
                                           scale: pool.config.scale)
            log.log(.end, name: "Downsample Data")

            self.queue.async {
                if let thumbnail = thumbnail {
                    self.enqueueEncodingOperation(pool, thumbnail: thumbnail)
                } else {
                    pool.didLoad(thumbnail: nil)
                }
            }
        }
        pool.ongoingOperation = operation
        config.downsamplingQueue.addOperation(operation)
    }

    private func enqueueEncodingOperation(_ pool: ThumbnailRequestPool, thumbnail: CGImage) {
        let operation = BlockOperation { [weak self, pool] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Encode CGImage")
            let encodedImage = self.encode(thumbnail, compressionRatio: self.config.compressionRatio)
            log.log(.end, name: "Encode CGImage")

            self.queue.async {
                guard let encodedImage = encodedImage else {
                    pool.didLoad(thumbnail: nil)
                    return
                }
                self.enqueueDiskCachingOperation(for: pool.config.cacheKey, data: encodedImage)
                self.enqueueDecompressingOperation(pool, data: encodedImage)
            }
        }
        pool.ongoingOperation = operation
        config.imageEncodingQueue.addOperation(operation)
    }

    private func enqueueDiskCachingOperation(for thumbnailId: String, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Store Cache")
            self.config.diskCache?.store(data, forKey: thumbnailId)
            log.log(.end, name: "Store Cache")
        }
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDecompressingOperation(_ pool: ThumbnailRequestPool, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Decompress Data")
            let image = self.decompress(data)
            log.log(.end, name: "Decompress Data")

            self.queue.async {
                self.config.memoryCache.insert(image, forKey: pool.config.cacheKey)

                pool.releasePrefetches()
                if pool.isEmpty { return }

                pool.didLoad(thumbnail: image)
            }
        }
        config.imageDecompressingQueue.addOperation(operation)
    }
}

// MARK: - ThumbnailRequestPoolObserver

extension ThumbnailLoadQueue: ThumbnailRequestPoolObserver {
    func didComplete(_ pool: ThumbnailRequestPool) {
        self.requestPools.removeValue(forKey: pool.config.cacheKey)
    }
}

// MARK: Image Processing

extension ThumbnailLoadQueue {
    private func decompress(_ data: Data) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
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

public extension CGImageAlphaInfo {
    var hasAlphaChannel: Bool {
        switch self {
        case .none, .noneSkipLast, .noneSkipFirst:
            return false

        default:
            return true
        }
    }
}
