//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public final class Pipeline {
    typealias Key = ImageRequestKey

    public struct Configuration {
        public var memoryCache: MemoryCaching = MemoryCache()
        public var diskCache: DiskCaching?
        public var compressionRatio: Float = 0.8

        public let dataLoadingQueue = OperationQueue()
        public let dataCachingQueue = OperationQueue()
        public let downsamplingQueue = OperationQueue()
        public let imageEncodingQueue = OperationQueue()
        public let imageDecompressingQueue = OperationQueue()

        public init() {
            self.dataLoadingQueue.maxConcurrentOperationCount = 1
            self.dataCachingQueue.maxConcurrentOperationCount = 3
            self.downsamplingQueue.maxConcurrentOperationCount = 2
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageDecompressingQueue.maxConcurrentOperationCount = 2
        }
    }

    public let config: Configuration

    let logger = Logger()
    let queue = DispatchQueue(label: "net.tasuwo.TBox.Smoothie.Pipeline", target: .global(qos: .userInitiated))
    let pool = ImageLoadTaskPool()

    // MARK: - Initializers

    public init(config: Configuration = .init()) {
        self.config = config
    }
}

// MARK: Load

extension Pipeline {
    func loadImage(_ request: ImageRequest, completion: @escaping (UIImage?) -> Void) -> ImageLoadTaskCancellable {
        return queue.sync {
            pool
                .task(for: ImageRequestKey(request)) {
                    ImageLoadTask(request: request, pipeline: self)
                }
                .subscribe(completion: completion)
        }
    }
}

// MARK: Operations

extension Pipeline {
    func startLoading(_ task: ImageLoadTask) {
        enqueueCheckCacheOperation(task)
    }

    private func enqueueCheckCacheOperation(_ task: ImageLoadTask) {
        let operation = BlockOperation { [weak self, task] in
            guard let self = self else { return }

            let data = self.config.diskCache?[task.request.source.cacheKey]

            self.queue.async {
                guard let data = data else {
                    self.enqueueDataLoadingOperation(task)
                    return
                }

                self.enqueueDecompressingOperation(task, data: data)
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
            switch task.request.source {
            case let .provider(provider):
                provider.load { data in
                    log.log(.end, name: "Load Original Data")

                    self.queue.async {
                        if let data = data {
                            self.enqueueDownsamplingOperation(task, data: data)
                        } else {
                            task.didLoad(nil)
                        }
                    }
                }
            }
        }
        task.ongoingOperation = operation
        config.dataLoadingQueue.addOperation(operation)
    }

    private func enqueueDownsamplingOperation(_ task: ImageLoadTask, data: Data) {
        let operation = BlockOperation { [weak self, task] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)
            log.log(.begin, name: "Downsample Data")
            let thumbnail = self.thumbnail(data: data,
                                           size: task.request.size,
                                           scale: task.request.scale)
            log.log(.end, name: "Downsample Data")

            self.queue.async {
                if let thumbnail = thumbnail {
                    self.enqueueEncodingOperation(task, thumbnail: thumbnail)
                } else {
                    task.didLoad(nil)
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
            let encodedImage = self.encode(thumbnail, compressionRatio: self.config.compressionRatio)
            log.log(.end, name: "Encode CGImage")

            self.queue.async {
                guard let encodedImage = encodedImage else {
                    task.didLoad(nil)
                    return
                }
                self.enqueueDiskCachingOperation(for: task.request.source.cacheKey, data: encodedImage)
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
            let image = self.decompress(data)
            log.log(.end, name: "Decompress Data")

            self.queue.async {
                self.config.memoryCache.insert(image, forKey: task.request.source.cacheKey)
                task.didLoad(image)
            }
        }
        config.imageDecompressingQueue.addOperation(operation)
    }
}

// MARK: Image Processing

extension Pipeline {
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
