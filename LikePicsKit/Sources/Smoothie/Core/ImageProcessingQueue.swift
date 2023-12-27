//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation
import ImageIO
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public final class ImageProcessingQueue {
    typealias Key = ImageRequestKey

    public struct Configuration {
        public var memoryCache: MemoryCaching = MemoryCache()
        public var diskCache: DiskCaching?
        public var compressionRatio: Float = 0.8

        public var dataLoadingQueue = OperationQueue()
        public var dataCachingQueue = OperationQueue()
        public var downsamplingQueue = OperationQueue()
        public var imageEncodingQueue = OperationQueue()
        public var imageDecompressingQueue = OperationQueue()

        public init() {
            self.dataLoadingQueue.maxConcurrentOperationCount = 1
            self.dataCachingQueue.maxConcurrentOperationCount = 3
            self.downsamplingQueue.maxConcurrentOperationCount = 2
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageDecompressingQueue.maxConcurrentOperationCount = 2
        }
    }

    // MARK: - Properties

    public let config: Configuration

    private let logger = Logger()
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Smoothie.ImageProcessingQueue", target: .global(qos: .userInitiated))
    private let pool = ImageLoadTaskPool()

    // MARK: - Initializers

    public init(config: Configuration = .init()) {
        self.config = config
    }
}

// MARK: Preload

public extension ImageProcessingQueue {
    func loadImage(_ request: ImageRequest, completion: (() -> Void)? = nil) -> ImageLoadTaskCancellable {
        return queue.sync {
            pool
                .task(for: ImageRequestKey(request)) {
                    ImageLoadTask(request: request, processingQueue: self)
                }
                .subscribe { _ in
                    completion?()
                }
        }
    }
}

// MARK: Load

extension ImageProcessingQueue {
    func loadImage(_ request: ImageRequest, completion: @escaping (ImageResponse?) -> Void) -> ImageLoadTaskCancellable {
        return queue.sync {
            pool
                .task(for: ImageRequestKey(request)) {
                    ImageLoadTask(request: request, processingQueue: self)
                }
                .subscribe(completion: completion)
        }
    }
}

// MARK: Operations

extension ImageProcessingQueue {
    func startLoading(_ task: ImageLoadTask) {
        dispatchPrecondition(condition: .onQueue(queue))

        if let image = config.memoryCache[task.request.cacheKey] {
            if let cacheInvalidate = task.request.cacheInvalidate,
               cacheInvalidate(.init(width: image.size.width * (task.request.resize?.scale ?? 1),
                                     height: image.size.height * (task.request.resize?.scale ?? 1)))
            {
                config.memoryCache.remove(forKey: task.request.cacheKey)

                if task.request.ignoreDiskCaching {
                    enqueueDataLoadingOperation(task)
                } else {
                    enqueueCheckDiskCacheOperation(task)
                }
                return
            }

            task.didLoad(.init(image: image, diskCacheImageSize: nil, source: .memoryCache))
            return
        }

        if task.request.ignoreDiskCaching {
            enqueueDataLoadingOperation(task)
        } else {
            enqueueCheckDiskCacheOperation(task)
        }
    }

    private func enqueueCheckDiskCacheOperation(_ task: ImageLoadTask) {
        let operation = BlockOperation { [weak self, task] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)

            log.log(.begin, name: "Read from DiskCache")
            let data = self.config.diskCache?[task.request.cacheKey]
            log.log(.end, name: "Read from DiskCache")

            if let data = data {
                log.log(.begin, name: "Fetch pixel size of DiskCache data")
                let imageSize = data.pixelSize()
                log.log(.end, name: "Fetch pixel size of DiskCache data")

                if let imageSize, let cacheInvalidate = task.request.cacheInvalidate, cacheInvalidate(imageSize) {
                    self.config.diskCache?.remove(forKey: task.request.cacheKey)
                    self.enqueueDataLoadingOperation(task)
                    return
                }

                self.queue.async {
                    self.enqueueDownsamplingDiskCacheOperation(task, data: data, diskCacheImageSize: imageSize)
                }
            } else {
                self.queue.async {
                    self.enqueueDataLoadingOperation(task)
                }
            }
        }
        task.ongoingOperation = operation
        config.dataCachingQueue.addOperation(operation)
    }

    private func enqueueDataLoadingOperation(_ task: ImageLoadTask) {
        let operation = BlockOperation { [weak self, task] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Load Original Data")
            Task {
                let data = await task.request.data()
                log.log(.end, name: "Load Original Data")
                self.queue.async {
                    if let data = data {
                        self.enqueueDownsampleOperation(task, data: data)
                    } else {
                        task.didLoad(nil)
                    }
                }
            }
        }
        task.ongoingOperation = operation
        config.dataLoadingQueue.addOperation(operation)
    }

    private func enqueueDownsampleOperation(_ task: ImageLoadTask, data: Data) {
        let operation = BlockOperation { [weak self, task] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Downsample Data")
            let thumbnail = data.downsample(size: task.request.resize?.size,
                                            scale: task.request.resize?.scale)
            log.log(.end, name: "Downsample Data")

            self.queue.async {
                guard let thumbnail = thumbnail else {
                    task.didLoad(nil)
                    return
                }
                if task.request.resize == nil {
                    // リサイズが不要なら、エンコードは行わない
                    #if canImport(UIKit)
                    let image = UIImage(cgImage: thumbnail)
                    #endif
                    #if canImport(AppKit)
                    let image = NSImage(cgImage: thumbnail, size: .init(width: thumbnail.width, height: thumbnail.height))
                    #endif
                    self.config.memoryCache.insert(image, forKey: task.request.cacheKey)
                    task.didLoad(.init(image: image, diskCacheImageSize: nil, source: .processed))
                } else {
                    self.enqueueEncodingOperation(task, thumbnail: thumbnail)
                }
            }
        }
        task.ongoingOperation = operation
        config.downsamplingQueue.addOperation(operation)
    }

    private func enqueueEncodingOperation(_ task: ImageLoadTask, thumbnail: CGImage) {
        let operation = BlockOperation { [weak self, task] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Encode CGImage")
            let encodedImage = thumbnail.encode(compressionRatio: self.config.compressionRatio)
            log.log(.end, name: "Encode CGImage")

            self.queue.async {
                guard let encodedImage = encodedImage else {
                    task.didLoad(nil)
                    return
                }

                self.enqueueDiskCachingOperation(for: task.request.cacheKey, data: encodedImage)

                self.enqueueDecompressingOperation(task, data: encodedImage)
            }
        }
        task.ongoingOperation = operation
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

    private func enqueueDecompressingOperation(_ task: ImageLoadTask, data: Data) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Decompress Data")
            #if canImport(UIKit)
            let image: UIImage? = {
                guard let image = data.downsample() else { return nil }
                return UIImage(cgImage: image)
            }()
            #endif
            #if canImport(AppKit)
            let image: NSImage? = {
                guard let image = data.downsample() else { return nil }
                return NSImage(cgImage: image, size: .init(width: image.width, height: image.height))
            }()
            #endif
            log.log(.end, name: "Decompress Data")

            self.queue.async {
                self.config.memoryCache.insert(image, forKey: task.request.cacheKey)

                if let image = image {
                    task.didLoad(.init(image: image, diskCacheImageSize: nil, source: .processed))
                } else {
                    task.didLoad(nil)
                }
            }
        }
        config.imageDecompressingQueue.addOperation(operation)
    }

    private func enqueueDownsamplingDiskCacheOperation(_ task: ImageLoadTask, data: Data, diskCacheImageSize: CGSize?) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Downsample Data")
            let thumbnail = data.downsample(size: task.request.resize?.size,
                                            scale: task.request.resize?.scale)
            log.log(.end, name: "Downsample Data")

            self.queue.async {
                guard let thumbnail = thumbnail else {
                    task.didLoad(nil)
                    return
                }
                #if canImport(UIKit)
                let image = UIImage(cgImage: thumbnail)
                #endif
                #if canImport(AppKit)
                let image = NSImage(cgImage: thumbnail, size: .init(width: thumbnail.width, height: thumbnail.height))
                #endif
                self.config.memoryCache.insert(image, forKey: task.request.cacheKey)
                task.didLoad(ImageResponse(image: image, diskCacheImageSize: diskCacheImageSize, source: .diskCache))
            }
        }
        config.imageDecompressingQueue.addOperation(operation)
    }
}

// MARK: Image Processing

private extension Data {
    func pixelSize() -> CGSize? {
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

        return CGSize(width: pixelWidth, height: pixelHeight)
    }

    func downsample(size: CGSize? = nil, scale: CGFloat? = nil) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else {
            return nil
        }

        var options: [AnyHashable: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        if let size = size {
            let maxDimensionInPixels = Swift.max(size.width, size.height) * (scale ?? 1)
            options[kCGImageSourceThumbnailMaxPixelSize] = maxDimensionInPixels
        }

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return downsampledImage
    }
}

private extension CGImage {
    func encode(compressionRatio: Float) -> Data? {
        let type: ImageType = self.alphaInfo.hasAlphaChannel ? .png : .jpeg

        let mutableData = NSMutableData()
        let options: NSDictionary = [
            kCGImageDestinationLossyCompressionQuality: compressionRatio
        ]

        guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, type.uniformTypeIdentifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, self, options)
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
