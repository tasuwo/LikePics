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

    // MARK: - Properties

    public let config: Configuration

    private let logger = Logger()
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Smoothie.Pipeline", target: .global(qos: .userInitiated))
    private let pool = ImageLoadTaskPool()

    // MARK: - Initializers

    public init(config: Configuration = .init()) {
        self.config = config
    }
}

// MARK: Load

extension Pipeline {
    func loadImage(_ request: ImageRequest, completion: @escaping (ImageResponse?) -> Void) -> ImageLoadTaskCancellable {
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
        enqueueCheckDiskCacheOperation(task)
    }

    private func enqueueCheckDiskCacheOperation(_ task: ImageLoadTask) {
        let operation = BlockOperation { [weak self, task] in
            guard let self = self else { return }

            let log = Log(logger: self.logger)

            log.log(.begin, name: "Read from DiskCache")
            let data = self.config.diskCache?[task.request.source.cacheKey]
            log.log(.end, name: "Read from DiskCache")

            if let data = data {
                log.log(.begin, name: "Fetch pixel size of DiskCache data")
                let imageSize = data.pixelSize()
                log.log(.end, name: "Fetch pixel size of DiskCache data")

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
            switch task.request.source {
            case let .provider(provider):
                provider.load { data in
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
                    // FIXME: 必要ならディスクキャッシュを行う
                    let image = UIImage(cgImage: thumbnail)
                    self.config.memoryCache.insert(image, forKey: task.request.source.cacheKey)
                    task.didLoad(.init(image: image, diskCacheImageSize: nil))
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
            let image: UIImage? = {
                guard let image = data.downsample() else { return nil }
                return UIImage(cgImage: image)
            }()
            log.log(.end, name: "Decompress Data")

            self.queue.async {
                self.config.memoryCache.insert(image, forKey: task.request.source.cacheKey)

                if let image = image {
                    task.didLoad(.init(image: image, diskCacheImageSize: nil))
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
                let image = UIImage(cgImage: thumbnail)
                self.config.memoryCache.insert(image, forKey: task.request.source.cacheKey)
                task.didLoad(ImageResponse(image: image, diskCacheImageSize: diskCacheImageSize))
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
        let type: ImageType = {
            return self.alphaInfo.hasAlphaChannel ? .png : .jpeg
        }()

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
