//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import MobileCoreServices
import UIKit

public enum ImageCacheStorageError: Error {
    case notFound
    case failedToReadData
    case failedToConvertToImage
}

public class ImageCacheStorage {
    enum StorageConfiguration {
        static var directoryName: String = "TBoxThumbnails"

        static var cacheTargetUrl: URL {
            if let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                return directory.appendingPathComponent(self.directoryName, isDirectory: true)
            } else {
                fatalError("Failed to resolve directory url for image cache.")
            }
        }
    }

    private let storage: ImageStorageProtocol
    private let fileManager: FileManager
    private let baseUrl: URL
    private let logger: TBoxLoggable

    private let downsamplingQueue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.ImageCacheStorage.downsamplingQueue",
                                                  qos: .userInteractive,
                                                  attributes: .concurrent)
    private let ioQueue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.ImageCacheStorage.ioQueue",
                                        qos: .userInteractive)

    // MARK: - Lifecycle

    init(storage: ImageStorageProtocol,
         fileManager: FileManager = .default,
         cacheDirectoryUrl: URL = StorageConfiguration.cacheTargetUrl,
         logger: TBoxLoggable = RootLogger.shared) throws
    {
        self.storage = storage
        self.fileManager = fileManager
        self.baseUrl = cacheDirectoryUrl
        self.logger = logger

        try self.createDirectoryIfNeeded(at: self.baseUrl)
    }

    public convenience init() throws {
        try self.init(storage: try ImageStorage())
    }

    // MARK: - Methods

    public static func downsampledImage(url: URL, to pointSize: CGSize) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height)
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return downsampledImage
    }

    private func createDirectoryIfNeeded(at url: URL) throws {
        guard !self.fileManager.fileExists(atPath: url.path) else { return }
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    private func resolveCacheDirectoryUrl(forClipId clipId: Clip.Identity) -> URL {
        return self.baseUrl.appendingPathComponent(clipId, isDirectory: true)
    }

    private func resolveCacheImageFileUrl(fileName: String, clipId: Clip.Identity) -> URL {
        return self.resolveCacheDirectoryUrl(forClipId: clipId).appendingPathComponent(fileName, isDirectory: false)
    }

    private func existsCache(named fileName: String, inClipHaving clipId: Clip.Identity) -> Bool {
        let url = self.resolveCacheImageFileUrl(fileName: fileName, clipId: clipId)
        return self.fileManager.fileExists(atPath: url.path)
    }

    private func readCache(named name: String, inClipHaving clipId: Clip.Identity) throws -> UIImage {
        let fileUrl = self.resolveCacheImageFileUrl(fileName: name, clipId: clipId)

        guard let data = try? Data(contentsOf: fileUrl) else {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize Data by URL. (name=\(name), clipId=\(clipId))
            """))
            throw ImageCacheStorageError.failedToReadData
        }

        guard let image = UIImage(data: data) else {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize UIImage by Data. (name=\(name), clipId=\(clipId))
            """))
            throw ImageCacheStorageError.failedToConvertToImage
        }

        return image
    }

    private func createDirectoryIfNeeded(for item: ClipItem) throws {
        let clipDirectoryUrl = self.resolveCacheDirectoryUrl(forClipId: item.clipId)
        guard self.fileManager.fileExists(atPath: clipDirectoryUrl.path) == false else { return }
        try self.fileManager.createDirectory(at: clipDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
    }
}

extension ImageCacheStorage: ImageCacheStorageProtocol {
    public func clearCache() {
        guard self.fileManager.fileExists(atPath: self.baseUrl.path) else { return }
        try? self.fileManager.removeItem(at: self.baseUrl)
        try? self.createDirectoryIfNeeded(at: self.baseUrl)
    }

    public func requestThumbnail(for item: ClipItem, completion: @escaping (UIImage?) -> Void) {
        self.ioQueue.sync {
            guard !self.existsCache(named: item.imageFileName, inClipHaving: item.clipId) else {
                guard let image = try? self.readCache(named: item.imageFileName, inClipHaving: item.clipId) else {
                    completion(nil)
                    return
                }
                completion(image)
                return
            }

            do {
                try self.createDirectoryIfNeeded(for: item)
            } catch {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to create directory. (name=\(item.imageFileName), clipId=\(item.clipId)
                """))
                completion(nil)
            }
        }

        self.downsamplingQueue.async {
            guard let url = try? self.storage.readImageFileUrl(named: item.imageFileName, inClipHaving: item.clipId) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to resolve image file url. (name=\(item.imageFileName), clipId=\(item.clipId)
                """))
                completion(nil)
                return
            }

            let targetSize = Self.calcDownsamplingSize(for: item)

            guard let downsampledImage = Self.downsampledImage(url: url, to: targetSize) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to downsampling image. (name=\(item.imageFileName), clipId=\(item.clipId), url=\(url.absoluteString), targetSize=\(targetSize)
                """))
                completion(nil)
                return
            }

            let fileUrl = self.resolveCacheImageFileUrl(fileName: item.imageFileName, clipId: item.clipId)
            let utType = ImageExtensionResolver.resolveUTType(of: fileUrl)
            guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, utType, 1, nil) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to create CGIMageDestination. (name=\(item.imageFileName), clipId=\(item.clipId), fileUrl=\(fileUrl.absoluteString)
                """))
                completion(nil)
                return
            }

            self.ioQueue.sync {
                CGImageDestinationAddImage(destination, downsampledImage, nil)
                CGImageDestinationFinalize(destination)
                completion(UIImage(cgImage: downsampledImage))
            }
        }
    }
}
