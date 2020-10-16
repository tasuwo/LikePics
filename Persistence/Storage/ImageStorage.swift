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
    func save(_ image: Data, asName fileName: String, inClipHaving clipId: Clip.Identity) throws
    func delete(fileName: String, inClipHaving clipId: Clip.Identity) throws
    func deleteAll(inClipHaving clipId: Clip.Identity) throws
    func readImage(named name: String, inClipHaving clipId: Clip.Identity) throws -> Data
}

class ImageStorage {
    enum StorageConfiguration {
        static var directoryName: String = "TBoxImages"

        static var defaultTargetUrl: URL {
            if let appGroupIdentifier = Constants.appGroupIdentifier,
                let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            {
                return directory.appendingPathComponent(self.directoryName, isDirectory: true)
            } else {
                fatalError("Failed to resolve images containing directory url.")
            }
        }
    }

    private let fileManager: FileManager
    private let baseUrl: URL

    init(fileManager: FileManager = .default, targetDirectoryUrl: URL = StorageConfiguration.defaultTargetUrl) throws {
        self.fileManager = fileManager
        self.baseUrl = targetDirectoryUrl

        try self.createDirectoryIfNeeded()
        try self.setDirectoryAttributes([.protectionKey: FileProtectionType.complete])
    }

    // MARK: - Methods

    // MARK: Private

    private func setDirectoryAttributes(_ attributes: [FileAttributeKey: Any]) throws {
        try self.fileManager.setAttributes(attributes, ofItemAtPath: self.baseUrl.path)
    }

    private func createDirectoryIfNeeded() throws {
        guard !self.fileManager.fileExists(atPath: self.baseUrl.path) else { return }
        try self.fileManager.createDirectory(at: self.baseUrl, withIntermediateDirectories: true, attributes: nil)
    }

    private func resolveClipDirectoryUrl(forClipId clipId: Clip.Identity) -> URL {
        return self.baseUrl.appendingPathComponent(clipId, isDirectory: true)
    }

    private func resolveImageFileUrl(fileName: String, clipId: Clip.Identity) -> URL {
        return self.resolveClipDirectoryUrl(forClipId: clipId).appendingPathComponent(fileName, isDirectory: false)
    }
}

extension ImageStorage: ImageStorageProtocol {
    // MARK: - LegacyImageStorageProtocol

    func save(_ image: Data, asName fileName: String, inClipHaving clipId: Clip.Identity) throws {
        let clipDirectoryUrl = self.resolveClipDirectoryUrl(forClipId: clipId)

        if !self.fileManager.fileExists(atPath: clipDirectoryUrl.path) {
            try self.fileManager.createDirectory(at: clipDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        }

        let filePath = clipDirectoryUrl.appendingPathComponent(fileName, isDirectory: false).path
        switch self.fileManager.createFile(atPath: filePath, contents: image, attributes: nil) {
        case true:
            break

        case false:
            throw ImageStorageError.failedToCreateImageFile
        }
    }

    func delete(fileName: String, inClipHaving clipId: Clip.Identity) throws {
        let fileUrl = self.resolveImageFileUrl(fileName: fileName, clipId: clipId)

        guard self.fileManager.fileExists(atPath: fileUrl.path) else {
            throw ImageStorageError.notFound
        }

        try self.fileManager.removeItem(at: fileUrl)

        let clipDirectoryUrl = self.resolveClipDirectoryUrl(forClipId: clipId)
        if try self.fileManager.contentsOfDirectory(atPath: clipDirectoryUrl.path).isEmpty {
            try self.fileManager.removeItem(at: clipDirectoryUrl)
        }
    }

    func deleteAll(inClipHaving clipId: Clip.Identity) throws {
        let clipDirectoryUrl = self.resolveClipDirectoryUrl(forClipId: clipId)

        guard self.fileManager.fileExists(atPath: clipDirectoryUrl.path) else {
            throw ImageStorageError.notFound
        }

        try self.fileManager.removeItem(at: clipDirectoryUrl)
    }

    func readImage(named name: String, inClipHaving clipId: Clip.Identity) throws -> Data {
        let fileUrl = self.resolveImageFileUrl(fileName: name, clipId: clipId)

        guard self.fileManager.fileExists(atPath: fileUrl.path) else {
            throw ImageStorageError.notFound
        }

        return try Data(contentsOf: fileUrl)
    }
}
