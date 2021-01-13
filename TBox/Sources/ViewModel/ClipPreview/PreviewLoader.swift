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
    func preloadPreview(itemId: ClipItem.Identity, imageId: UUID)
}

class PreviewLoader {
    private let thumbnailMemoryCache: MemoryCaching
    private let thumbnailDiskCache: DiskCaching
    private let memoryCache: MemoryCaching
    private let imageQueryService: ImageQueryServiceProtocol

    private let loadingQueue = DispatchQueue(label: "net.tasuwo.TBox.PreviewLoader.loading")
    private let preloadLockQueue = DispatchQueue(label: "net.tasuwo.TBox.PreviewLoader.preloadLocking")
    private let downsamplingQueue = OperationQueue()

    private var loadingItemIds: Set<ClipItem.Identity> = []

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

        self.downsamplingQueue.maxConcurrentOperationCount = 2
    }

    // MARK: - Methods

    private func downsampledImage(for imageId: UUID) -> CGImage? {
        guard let data = try? imageQueryService.read(having: imageId) else {
            return nil
        }

        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else {
            return nil
        }

        let downsamplingOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsamplingOptions) else {
            return nil
        }

        return downsampledImage
    }

    private func insertToCache(imageId: UUID, image: CGImage) {
        let type: ImageType = {
            return image.alphaInfo.hasAlphaChannel ? .png : .jpeg
        }()

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, type.uniformTypeIdentifier as CFString, 1, nil) else {
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        memoryCache.insert(mutableData as Data, forKey: "preview-\(imageId.uuidString)")
    }
}

extension PreviewLoader: PreviewLoaderProtocol {
    // MARK: - PreviewLoaderProtocol

    func readThumbnail(forItemId itemId: ClipItem.Identity) -> UIImage? {
        // - SeeAlso: ClipCollectionProvider
        if let data = thumbnailMemoryCache["clip-collection-\(itemId.uuidString)"] {
            return UIImage(data: data)
        }

        if let data = thumbnailDiskCache["clip-collection-\(itemId.uuidString)"] {
            return UIImage(data: data)
        }

        return nil
    }

    func readCache(forImageId imageId: UUID) -> UIImage? {
        guard let data = memoryCache["preview-\(imageId.uuidString)"] else { return nil }
        return UIImage(data: data)
    }

    func loadPreview(forImageId imageId: UUID, completion: @escaping (UIImage?) -> Void) {
        loadingQueue.async {
            if let data = self.memoryCache["preview-\(imageId.uuidString)"] {
                completion(UIImage(data: data))
                return
            }

            guard let image = self.downsampledImage(for: imageId) else {
                completion(nil)
                return
            }

            let operation = BlockOperation { [weak self] in
                guard self?.memoryCache["preview-\(imageId.uuidString)"] == nil else { return }
                self?.insertToCache(imageId: imageId, image: image)
            }
            self.downsamplingQueue.addOperation(operation)

            completion(UIImage(cgImage: image))
        }
    }

    func preloadPreview(itemId: ClipItem.Identity, imageId: UUID) {
        guard self.memoryCache["preview-\(imageId.uuidString)"] == nil else { return }

        preloadLockQueue.sync {
            guard !self.loadingItemIds.contains(itemId) else { return }
            self.loadingItemIds.insert(itemId)

            let operation = BlockOperation { [weak self] in
                guard let self = self else { return }

                guard let image = self.downsampledImage(for: imageId) else { return }
                self.insertToCache(imageId: imageId, image: image)

                self.preloadLockQueue.async {
                    self.loadingItemIds.remove(itemId)
                }
            }

            downsamplingQueue.addOperation(operation)
        }
    }
}
