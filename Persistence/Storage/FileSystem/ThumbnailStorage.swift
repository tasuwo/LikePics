//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import MobileCoreServices
import UIKit

public enum ThumbnailStorageError: Error {
    case notFound
    case failedToReadData
    case failedToConvertToImage
}

public class ThumbnailStorage {
    public struct Configuration {
        let targetUrl: URL
    }

    private let queryService: NewImageQueryServiceProtocol
    private let fileManager: FileManager
    private let baseUrl: URL
    private let logger: TBoxLoggable

    private let queue = DispatchQueue(label: "net.tasuwo.TBox.ThumbnailStorage", qos: .userInitiated, attributes: .concurrent)

    // MARK: - Lifecycle

    init(queryService: NewImageQueryServiceProtocol,
         configuration: Configuration,
         fileManager: FileManager = .default,
         logger: TBoxLoggable = RootLogger.shared) throws
    {
        self.queryService = queryService
        self.baseUrl = configuration.targetUrl
        self.fileManager = fileManager
        self.logger = logger

        try self.createDirectoryIfNeeded(at: self.baseUrl)
    }

    public convenience init(queryService: NewImageQueryServiceProtocol, bundle: Bundle) throws {
        try self.init(queryService: queryService,
                      configuration: .resolve(for: bundle),
                      fileManager: .default,
                      logger: RootLogger.shared)
    }

    // MARK: - Methods

    public static func downsampledImage(data: Data, to pointSize: CGSize) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
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

    private func resolveCacheImageFileUrl(for item: ClipItem) -> URL {
        return self.baseUrl.appendingPathComponent("\(item.imageId.uuidString).\(item.imageFileName)", isDirectory: false)
    }

    private func existsCache(for item: ClipItem) -> Bool {
        let url = self.resolveCacheImageFileUrl(for: item)
        return self.fileManager.fileExists(atPath: url.path)
    }

    private func readCache(for item: ClipItem) throws -> UIImage {
        let fileUrl = self.resolveCacheImageFileUrl(for: item)

        guard let data = try? Data(contentsOf: fileUrl) else {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize Data by URL. (url=\(fileUrl))
            """))
            throw ThumbnailStorageError.failedToReadData
        }

        guard let image = UIImage(data: data) else {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize UIImage by Data. (url=\(fileUrl))
            """))
            throw ThumbnailStorageError.failedToConvertToImage
        }

        return image
    }
}

extension ThumbnailStorage: ThumbnailStorageProtocol {
    public func clearCache() {
        guard self.fileManager.fileExists(atPath: self.baseUrl.path) else { return }
        try? self.fileManager.removeItem(at: self.baseUrl)
        try? self.createDirectoryIfNeeded(at: self.baseUrl)
    }

    public func readThumbnailIfExists(for item: ClipItem) -> UIImage? {
        guard self.existsCache(for: item) else { return nil }
        return try? self.readCache(for: item)
    }

    public func requestThumbnail(for item: ClipItem, completion: @escaping (UIImage?) -> Void) {
        guard !self.existsCache(for: item) else {
            guard let image = try? self.readCache(for: item) else {
                completion(nil)
                return
            }
            completion(image)
            return
        }

        self.queue.async {
            guard let data = try? self.queryService.read(having: item.imageId) else {
                self.logger.write(ConsoleLog(level: .debug, message: """
                元画像ファイルの取得に失敗しました。iCloud同期前である可能性があります (name=\(item.imageFileName), clipId=\(item.clipId))
                """))
                completion(nil)
                return
            }

            let targetSize = Self.calcDownsamplingSize(for: item)

            guard let downsampledImage = Self.downsampledImage(data: data, to: targetSize) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to downsampling image. (name=\(item.imageId).\(item.imageFileName) targetSize=\(targetSize)
                """))
                completion(nil)
                return
            }

            let fileUrl = self.resolveCacheImageFileUrl(for: item)
            let utType = ImageExtensionResolver.resolveUTType(of: fileUrl)
            guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, utType, 1, nil) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to create CGIMageDestination. (fileUrl=\(fileUrl.absoluteString), targetSize=\(targetSize))
                """))
                completion(nil)
                return
            }

            CGImageDestinationAddImage(destination, downsampledImage, nil)
            CGImageDestinationFinalize(destination)

            completion(UIImage(cgImage: downsampledImage))
        }
    }

    public func deleteThumbnailCacheIfExists(for item: ClipItem) {
        guard self.existsCache(for: item) else { return }
        let fileUrl = self.resolveCacheImageFileUrl(for: item)
        try? self.fileManager.removeItem(at: fileUrl)
    }
}
