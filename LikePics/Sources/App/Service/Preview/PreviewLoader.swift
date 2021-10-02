//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

protocol PreviewLoaderProtocol {
    func readThumbnail(forItemId itemId: ClipItem.Identity) -> UIImage?
    func readCache(forImageId imageId: UUID) -> UIImage?
    func loadPreview(forImageId imageId: UUID, completion: @escaping (UIImage?) -> Void)
}

class PreviewLoader {
    private class LoadingPool {
        private class Publisher {
            var completions: [(UIImage?) -> Void] = []

            func append(_ completion: @escaping (UIImage?) -> Void) {
                completions.append(completion)
            }

            func publish(_ image: UIImage?) {
                completions.forEach { $0(image) }
            }
        }

        private var pool: [UUID: Publisher] = [:]

        func isLoading(imageId: UUID) -> Bool {
            pool[imageId] != nil
        }

        func append(imageId: UUID, completion: ((UIImage?) -> Void)? = nil) {
            if let publisher = pool[imageId] {
                if let completion = completion {
                    publisher.append(completion)
                }
            } else {
                let publisher = Publisher()
                if let completion = completion {
                    publisher.append(completion)
                }
                pool[imageId] = publisher
            }
        }

        func publish(imageId: UUID, image: UIImage?) {
            guard let publisher = pool[imageId] else { return }
            publisher.publish(image)
            pool.removeValue(forKey: imageId)
        }
    }

    private let thumbnailMemoryCache: MemoryCaching
    private let thumbnailDiskCache: DiskCaching
    private let memoryCache: MemoryCaching
    private let imageQueryService: ImageQueryServiceProtocol

    private let queue = DispatchQueue(label: "net.tasuwo.TBox.PreviewLoader.loading")
    private let decompressQueue = OperationQueue()

    private let pool = LoadingPool()

    // MARK: - Lifecycle

    init(thumbnailCache: MemoryCaching,
         thumbnailDiskCache: DiskCaching,
         imageQueryService: ImageQueryServiceProtocol,
         memoryCache: MemoryCaching)
    {
        self.thumbnailMemoryCache = thumbnailCache
        self.thumbnailDiskCache = thumbnailDiskCache
        self.memoryCache = memoryCache
        self.imageQueryService = imageQueryService

        self.decompressQueue.maxConcurrentOperationCount = 3
    }

    // MARK: - Methods

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

    private func addDecompressOperation(imageId: UUID) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            guard let data = try? self.imageQueryService.read(having: imageId),
                  let image = self.decompress(data)
            else {
                self.queue.async {
                    self.pool.publish(imageId: imageId, image: nil)
                }
                return
            }

            self.memoryCache.insert(image, forKey: "preview-\(imageId.uuidString)")

            self.queue.async {
                self.pool.publish(imageId: imageId, image: image)
            }
        }

        decompressQueue.addOperation(operation)
    }
}

extension PreviewLoader: PreviewLoaderProtocol {
    // MARK: - PreviewLoaderProtocol

    func readThumbnail(forItemId itemId: ClipItem.Identity) -> UIImage? {
        return queue.sync {
            // - SeeAlso: ClipCollectionViewLayout
            if let image = thumbnailMemoryCache["clip-collection-\(itemId.uuidString)"] {
                return image
            }

            // Note: 一時的な表示に利用するものなので、表示速度を優先し decompress はしない
            if let data = thumbnailDiskCache["clip-collection-\(itemId.uuidString)"] {
                return UIImage(data: data)
            }

            return nil
        }
    }

    func readCache(forImageId imageId: UUID) -> UIImage? {
        return queue.sync {
            guard let image = memoryCache["preview-\(imageId.uuidString)"] else { return nil }
            return image
        }
    }

    func loadPreview(forImageId imageId: UUID, completion: @escaping (UIImage?) -> Void) {
        queue.async {
            if let image = self.memoryCache["preview-\(imageId.uuidString)"] {
                completion(image)
                return
            }

            if self.pool.isLoading(imageId: imageId) {
                self.pool.append(imageId: imageId, completion: completion)
                return
            }

            self.pool.append(imageId: imageId, completion: completion)

            self.addDecompressOperation(imageId: imageId)
        }
    }
}
