//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public class TemporaryImageStorage {
    public struct Configuration {
        let targetUrl: URL
    }

    private let fileManager: FileManager
    private let baseUrl: URL

    // MARK: - Lifecycle

    public init(configuration: Configuration,
                fileManager: FileManager = .default) throws
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

    private func buildTargetDirectoryUrl(for clipId: Domain.Clip.Identity) -> URL {
        return self.baseUrl.appendingPathComponent(clipId.uuidString, isDirectory: true)
    }

    private func buildImageFileUrl(name: String, clipId: Domain.Clip.Identity) -> URL {
        return self.buildTargetDirectoryUrl(for: clipId).appendingPathComponent(name, isDirectory: false)
    }
}

extension TemporaryImageStorage: TemporaryImageStorageProtocol {
    // MARK: - ItemStorageProtocol

    public func imageFileExists(named name: String, inClipHaving clipId: Domain.Clip.Identity) -> Bool {
        let fileUrl = self.buildImageFileUrl(name: name, clipId: clipId)
        return self.fileManager.fileExists(atPath: fileUrl.path)
    }

    public func save(_ image: Data, asName fileName: String, inClipHaving clipId: Domain.Clip.Identity) throws {
        let directory = self.buildTargetDirectoryUrl(for: clipId)

        try Self.createDirectoryIfNeeded(at: directory, using: self.fileManager)

        let filePath = self.buildImageFileUrl(name: fileName, clipId: clipId).path
        self.fileManager.createFile(atPath: filePath, contents: image, attributes: nil)
    }

    public func delete(fileName: String, inClipHaving clipId: Domain.Clip.Identity) throws {
        let fileUrl = self.buildImageFileUrl(name: fileName, clipId: clipId)
        guard self.fileManager.fileExists(atPath: fileUrl.path) else { return }

        // Delete file
        try self.fileManager.removeItem(at: fileUrl)

        // Delete directory if needed
        let directory = self.buildTargetDirectoryUrl(for: clipId)
        if try self.fileManager.contentsOfDirectory(atPath: directory.path).isEmpty {
            try self.fileManager.removeItem(at: directory)
        }
    }

    public func deleteAll(inClipHaving clipId: Domain.Clip.Identity) throws {
        let directory = self.buildTargetDirectoryUrl(for: clipId)
        guard self.fileManager.fileExists(atPath: directory.path) else { return }
        try self.fileManager.removeItem(at: directory)
    }

    public func deleteAll() throws {
        try self.fileManager.removeItem(at: self.baseUrl)
        try Self.createDirectoryIfNeeded(at: self.baseUrl, using: self.fileManager)
    }

    public func readImage(named name: String, inClipHaving clipId: Domain.Clip.Identity) throws -> Data? {
        let fileUrl = self.buildImageFileUrl(name: name, clipId: clipId)
        guard self.fileManager.fileExists(atPath: fileUrl.path) else { return nil }
        return try Data(contentsOf: fileUrl)
    }
}
