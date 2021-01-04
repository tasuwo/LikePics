//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import os
import UIKit

public class ThumbnailLoadPipeline {
    typealias ThumbnailId = String

    public struct Configuration {
        public var memoryCache: MemoryCaching = MemoryCache()
        public var diskCache: DiskCaching?
        public var compressionRatio: Float = 0.8
        public var dataLoader: OriginalImageLoader

        public let dataLoadingQueue = OperationQueue()
        public let dataCachingQueue = OperationQueue()
        public let downsamplingQueue = OperationQueue()
        public let imageEncodingQueue = OperationQueue()
        public let imageDecompressingQueue = OperationQueue()

        public init(dataLoader: OriginalImageLoader) {
            self.dataLoader = dataLoader

            self.dataLoadingQueue.maxConcurrentOperationCount = 1
            self.dataCachingQueue.maxConcurrentOperationCount = 1
            self.downsamplingQueue.maxConcurrentOperationCount = 2
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageDecompressingQueue.maxConcurrentOperationCount = 1
        }
    }

    private struct Context {
        let request: ThumbnailRequest
        let task: ThumbnailLoadTask
        let didLoad: (UIImage?) -> Void
        let didFinish: () -> Bool
    }

    public let config: Configuration

    private let logger = Logger()
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.ThumbnailLoadPipeline", target: .global(qos: .userInitiated))

    private var tasks: [ThumbnailId: ThumbnailLoadTask] = [:]

    // MARK: - Lifecycle

    public init(config: Configuration) {
        self.config = config
    }

    // MARK: - Methods

    func readCacheIfExists(for request: ThumbnailRequest) -> UIImage? {
        if let data = config.memoryCache[request.thumbnailInfo.id],
            let image = decompress(data)
        {
            return image
        }

        if let data = config.diskCache?[request.thumbnailInfo.id],
            let image = decompress(data)
        {
            config.memoryCache[request.thumbnailInfo.id] = data
            return image
        }

        return nil
    }

    func load(for request: ThumbnailRequest, observer: ThumbnailLoadObserver?) {
        queue.async { [weak self, weak observer] in
            guard let self = self else { return }

            if let task = self.tasks[request.thumbnailInfo.id] {
                task.append(request, observer: observer)
                return
            }

            let task = ThumbnailLoadTask(thumbnailId: request.thumbnailInfo.id)
            task.delegate = self
            task.append(request, observer: observer)
            self.tasks[request.thumbnailInfo.id] = task

            let context = Context(request: request, task: task) {
                task.didLoad(image: $0)
            } didFinish: {
                if task.finish(requestId: request.requestId) {
                    self.tasks.removeValue(forKey: request.thumbnailInfo.id)
                    return true
                }
                return false
            }

            if let data = self.config.memoryCache[request.thumbnailInfo.id] {
                if request.isPrefetch { if context.didFinish() { return } }
                self.enqueueDecompressingOperation(context: context, data: data)
            } else {
                self.enqueueCheckCacheOperation(context: context)
            }
        }
    }

    func cancel(_ request: ThumbnailRequest) {
        queue.async { [weak self] in
            guard let self = self, let task = self.tasks[request.thumbnailInfo.id] else { return }
            task.cancel(requestId: request.requestId)
        }
    }
}

// MARK: Operations

extension ThumbnailLoadPipeline {
    private func enqueueCheckCacheOperation(context: Context) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Read Disk Cache")
            let data = self.config.diskCache?[context.request.thumbnailInfo.id]
            log.log(.end, name: "Read Disk Cache")

            self.queue.async {
                if let data = data {
                    if context.request.isPrefetch { if context.didFinish() { return } }
                    self.enqueueDecompressingOperation(context: context, data: data)
                } else {
                    self.enqueueDataLoadingOperation(context: context)
                }
            }
        }
        context.task.dependentOperation = operation
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDataLoadingOperation(context: Context) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Load Original Data")
            let data = self.config.dataLoader.loadData(with: context.request.imageRequest)
            log.log(.end, name: "Load Original Data")

            self.queue.async {
                if let data = data {
                    self.enqueueDownsamplingOperation(context: context, data: data)
                } else {
                    context.didLoad(nil)
                }
            }
        }
        context.task.dependentOperation = operation
        config.dataLoadingQueue.addOperation(operation)
    }

    private func enqueueDownsamplingOperation(context: Context, data: Data) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Downsample Data")
            let thumbnail = self.thumbnail(data: data,
                                           size: context.request.thumbnailInfo.size,
                                           scale: context.request.thumbnailInfo.scale)
            log.log(.end, name: "Downsample Data")

            self.queue.async {
                if let thumbnail = thumbnail {
                    self.enqueueEncodingOperation(context: context, thumbnail: thumbnail)
                } else {
                    context.didLoad(nil)
                }
            }
        }
        context.task.dependentOperation = operation
        config.downsamplingQueue.addOperation(operation)
    }

    private func enqueueEncodingOperation(context: Context, thumbnail: CGImage) {
        let operation = BlockOperation { [weak self, context] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Encode CGImage")
            let encodedImage = self.encode(thumbnail, compressionRatio: self.config.compressionRatio)
            log.log(.end, name: "Encode CGImage")

            self.queue.async {
                if let encodedImage = encodedImage {
                    if !context.request.isPrefetch {
                        self.config.memoryCache.insert(encodedImage, forKey: context.request.thumbnailInfo.id)
                    }
                    self.enqueueCachingOperation(for: context.request, data: encodedImage)
                    if context.request.isPrefetch { if context.didFinish() { return } }
                    self.enqueueDecompressingOperation(context: context, data: encodedImage)
                } else {
                    context.didLoad(nil)
                }
            }
        }
        context.task.dependentOperation = operation
        config.imageEncodingQueue.addOperation(operation)
    }

    private func enqueueCachingOperation(for request: ThumbnailRequest, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Store Cache")
            self.config.diskCache?.store(data, forKey: request.thumbnailInfo.id)
            log.log(.end, name: "Store Cache")
        }
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDecompressingOperation(context: Context, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Decompress Data")
            let image = self.decompress(data)
            log.log(.end, name: "Decompress Data")

            self.queue.async {
                context.didLoad(image)
            }
        }
        config.imageDecompressingQueue.addOperation(operation)
    }
}

extension ThumbnailLoadPipeline: ThumbnailLoadTaskDelegate {
    // MARK: - ThumbnailLoadTaskDelegate

    func didComplete(_ task: ThumbnailLoadTask) {
        self.tasks.removeValue(forKey: task.thumbnailId)
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
