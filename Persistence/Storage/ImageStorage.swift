//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

public enum ImageStorageError: Error {
    case failedToCreateImageFile
    case notFound
}

/// @mockable
public protocol ImageStorageProtocol {
    func imageFileExists(named name: String, inClipHaving clipId: Clip.Identity) -> Bool
    func save(_ image: Data, asName fileName: String, inClipHaving clipId: Clip.Identity) throws
    func delete(fileName: String, inClipHaving clipId: Clip.Identity) throws
    func deleteAll(inClipHaving clipId: Clip.Identity) throws
    func readImage(named name: String, inClipHaving clipId: Clip.Identity) throws -> Data
    func resolveImageFileUrl(named name: String, inClipHaving clipId: Clip.Identity) throws -> URL
}

public class ImageStorage {
    public struct Configuration {
        let targetUrl: URL
    }

    private let fileManager: FileManager
    private let baseUrl: URL

    // MARK: - Lifecycle

    public init(fileManager: FileManager = .default,
                configuration: Configuration = Constants.imageStorageConfiguration) throws
    {
        self.fileManager = fileManager
        self.baseUrl = configuration.targetUrl

        try Self.createDirectoryIfNeeded(at: self.baseUrl, using: self.fileManager)
        try self.fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: self.baseUrl.path)
    }

    // MARK: - Methods

    // MARK: Privates

    private static func createDirectoryIfNeeded(at url: URL, using fileManager: FileManager) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    private func buildTargetDirectoryUrl(for clipId: Clip.Identity) -> URL {
        return self.baseUrl.appendingPathComponent(clipId, isDirectory: true)
    }

    private func buildImageFileUrl(name: String, clipId: Clip.Identity) -> URL {
        return self.buildTargetDirectoryUrl(for: clipId).appendingPathComponent(name, isDirectory: false)
    }
}

extension ImageStorage: ImageStorageProtocol {
    // MARK: - ItemStorageProtocol

    public func imageFileExists(named name: String, inClipHaving clipId: Clip.Identity) -> Bool {
        let fileUrl = self.buildImageFileUrl(name: name, clipId: clipId)
        return self.fileManager.fileExists(atPath: fileUrl.path)
    }

    public func save(_ image: Data, asName fileName: String, inClipHaving clipId: Clip.Identity) throws {
        let directory = self.buildTargetDirectoryUrl(for: clipId)

        try Self.createDirectoryIfNeeded(at: directory, using: self.fileManager)

        let filePath = self.buildImageFileUrl(name: fileName, clipId: clipId).path
        switch self.fileManager.createFile(atPath: filePath, contents: image, attributes: nil) {
        case true:
            break

        case false:
            throw ImageStorageError.failedToCreateImageFile
        }
    }

    public func delete(fileName: String, inClipHaving clipId: Clip.Identity) throws {
        let fileUrl = self.buildImageFileUrl(name: fileName, clipId: clipId)

        guard self.fileManager.fileExists(atPath: fileUrl.path) else {
            throw ImageStorageError.notFound
        }

        // Delete file
        try self.fileManager.removeItem(at: fileUrl)

        // Delete directory if needed
        let directory = self.buildTargetDirectoryUrl(for: clipId)
        if try self.fileManager.contentsOfDirectory(atPath: directory.path).isEmpty {
            try self.fileManager.removeItem(at: directory)
        }
    }

    public func deleteAll(inClipHaving clipId: Clip.Identity) throws {
        let directory = self.buildTargetDirectoryUrl(for: clipId)

        guard self.fileManager.fileExists(atPath: directory.path) else {
            throw ImageStorageError.notFound
        }

        try self.fileManager.removeItem(at: directory)
    }

    public func readImage(named name: String, inClipHaving clipId: Clip.Identity) throws -> Data {
        let fileUrl = self.buildImageFileUrl(name: name, clipId: clipId)

        guard self.fileManager.fileExists(atPath: fileUrl.path) else {
            throw ImageStorageError.notFound
        }

        return try Data(contentsOf: fileUrl)
    }

    public func resolveImageFileUrl(named name: String, inClipHaving clipId: Clip.Identity) throws -> URL {
        let fileUrl = self.buildImageFileUrl(name: name, clipId: clipId)

        guard self.fileManager.fileExists(atPath: fileUrl.path) else {
            throw ImageStorageError.notFound
        }

        return fileUrl
    }
}
