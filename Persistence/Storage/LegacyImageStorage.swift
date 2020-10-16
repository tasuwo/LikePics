//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum ImageStorageError: Error {
    case failedToCreateImageFile
    case notFound
}

/// @mockable
public protocol LegacyImageStorageProtocol {
    func save(_ image: Data, asName fileName: String, inClip url: URL) throws
    func delete(fileName: String, inClip url: URL) throws
    func deleteAll(inClip url: URL) throws
    func readImage(named name: String, inClip url: URL) throws -> Data
}

class LegacyImageStorage {
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

    /**
     * See: https://www.quora.com/What-are-illegal-characters-in-filename-in-ios
     */
    private static func resolveDirectoryName(forClip url: URL) -> String {
        return url.absoluteString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ";", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "|", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private func setDirectoryAttributes(_ attributes: [FileAttributeKey: Any]) throws {
        try self.fileManager.setAttributes(attributes, ofItemAtPath: self.baseUrl.path)
    }

    private func createDirectoryIfNeeded() throws {
        guard !self.fileManager.fileExists(atPath: self.baseUrl.path) else { return }
        try self.fileManager.createDirectory(at: self.baseUrl, withIntermediateDirectories: true, attributes: nil)
    }

    private func resolveClipDirectoryUrl(for url: URL) -> URL {
        return self.baseUrl.appendingPathComponent(Self.resolveDirectoryName(forClip: url), isDirectory: true)
    }

    private func resolveImageFileUrl(fileName: String, clipUrl url: URL) -> URL {
        return self.resolveClipDirectoryUrl(for: url).appendingPathComponent(fileName, isDirectory: false)
    }
}

extension LegacyImageStorage: LegacyImageStorageProtocol {
    // MARK: - LegacyImageStorageProtocol

    func save(_ image: Data, asName fileName: String, inClip url: URL) throws {
        let clipDirectoryUrl = self.resolveClipDirectoryUrl(for: url)

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

    func delete(fileName: String, inClip url: URL) throws {
        let fileUrl = self.resolveImageFileUrl(fileName: fileName, clipUrl: url)

        guard self.fileManager.fileExists(atPath: fileUrl.path) else {
            throw ImageStorageError.notFound
        }

        try self.fileManager.removeItem(at: fileUrl)

        let clipDirectoryUrl = self.resolveClipDirectoryUrl(for: url)
        if try self.fileManager.contentsOfDirectory(atPath: clipDirectoryUrl.path).isEmpty {
            try self.fileManager.removeItem(at: clipDirectoryUrl)
        }
    }

    func deleteAll(inClip url: URL) throws {
        let clipDirectoryUrl = self.resolveClipDirectoryUrl(for: url)

        guard self.fileManager.fileExists(atPath: clipDirectoryUrl.path) else {
            throw ImageStorageError.notFound
        }

        try self.fileManager.removeItem(at: clipDirectoryUrl)
    }

    func readImage(named name: String, inClip url: URL) throws -> Data {
        let fileUrl = self.resolveImageFileUrl(fileName: name, clipUrl: url)

        guard self.fileManager.fileExists(atPath: fileUrl.path) else {
            throw ImageStorageError.notFound
        }

        return try Data(contentsOf: fileUrl)
    }
}
