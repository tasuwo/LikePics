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

    private let fileManager: FileManager
    private let baseUrl: URL
    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    init(configuration: Configuration,
         fileManager: FileManager = .default,
         logger: TBoxLoggable = RootLogger.shared) throws
    {
        self.baseUrl = configuration.targetUrl
        self.fileManager = fileManager
        self.logger = logger

        try self.createDirectoryIfNeeded(at: self.baseUrl)
    }

    public convenience init(bundle: Bundle) throws {
        try self.init(configuration: .resolve(for: bundle),
                      fileManager: .default,
                      logger: RootLogger.shared)
    }

    // MARK: - Methods

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

    private func readCache(for item: ClipItem) throws -> Data {
        let fileUrl = self.resolveCacheImageFileUrl(for: item)

        guard let data = try? Data(contentsOf: fileUrl) else {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize Data by URL. (url=\(fileUrl))
            """))
            throw ThumbnailStorageError.failedToReadData
        }

        return data
    }
}

extension ThumbnailStorage: ThumbnailStorageProtocol {
    // MARK: - ThumbnailStorageProtocol

    public func clearCache() {
        guard self.fileManager.fileExists(atPath: self.baseUrl.path) else { return }
        try? self.fileManager.removeItem(at: self.baseUrl)
        try? self.createDirectoryIfNeeded(at: self.baseUrl)
    }

    public func save(_ image: CGImage, for item: ClipItem) -> Bool {
        let fileUrl = self.resolveCacheImageFileUrl(for: item)
        let utType = ImageExtensionResolver.resolveUTType(of: fileUrl)
        guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, utType, 1, nil) else {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to create CGImageDestination. (fileUrl=\(fileUrl.absoluteString))
            """))
            return false
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        return true
    }

    public func delete(for item: ClipItem) -> Bool {
        guard self.existsCache(for: item) else { return true }
        let fileUrl = self.resolveCacheImageFileUrl(for: item)
        do {
            try self.fileManager.removeItem(at: fileUrl)
            return true
        } catch {
            return false
        }
    }

    public func resolveImageUrl(for item: ClipItem) -> URL? {
        guard self.existsCache(for: item) else { return nil }
        return self.resolveCacheImageFileUrl(for: item)
    }
}
