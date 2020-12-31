//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol DiskCaching: AnyObject {
    func store(_ data: Data?, forKey key: String)
    func remove(forKey key: String)
    func removeAll()
    subscript(_ key: String) -> Data? { get set }
}

public final class DiskCache {
    public struct Configuration {
        public static let `default` = Configuration(
            sizeLimit: 1024 * 1024 * 1024,
            countLimit: 1000,
            fileNameResolver: { $0.sha256() }
        )

        public let sizeLimit: Int
        public let countLimit: Int
        public let fileNameResolver: (_ key: String) -> String?
    }

    public var initialSweepDelay: TimeInterval = 10
    public var sweepInterval: TimeInterval = 30

    private let url: URL
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.DiskCache.IOQueue", target: .global(qos: .utility))
    private let config: Configuration

    // MARK: - Lifecycle

    public init(path: URL, config: Configuration = .default) throws {
        self.url = path
        self.config = config
        try self.setup()
    }

    // MARK: - Methods

    private func setup() throws {
        try createDirectoryIfNeeded(at: url)
        queue.asyncAfter(deadline: .now() + initialSweepDelay) { [weak self] in
            self?.performAndScheduleSweep()
        }
    }

    private func createDirectoryIfNeeded(at url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    private func resolveCacheUrl(for key: String) -> URL? {
        guard let fileName = config.fileNameResolver(key) else { return nil }
        return url.appendingPathComponent(fileName, isDirectory: false)
    }
}

// MARK: - File System

extension DiskCache {
    struct Content {
        let url: URL
        let fileSize: Int
        let accessDate: Date
    }

    func contents() -> [Content] {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .contentAccessDateKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: .skipsHiddenFiles) else { return [] }
        return contents
            .compactMap { content in
                guard let values = try? content.resourceValues(forKeys: Set(keys)) else { return nil }
                return Content(url: content,
                               fileSize: values.fileAllocatedSize ?? 0,
                               accessDate: values.contentAccessDate ?? Date.distantPast)
            }
    }
}

extension Array where Element == DiskCache.Content {
    var totalSize: Int {
        return self
            .map { $0.fileSize }
            .reduce(0, +)
    }
}

// MARK: - Sweep

extension DiskCache {
    private func performAndScheduleSweep() {
        performSweep()
        queue.asyncAfter(deadline: .now() + sweepInterval) { [weak self] in
            self?.performAndScheduleSweep()
        }
    }

    private func performSweep() {
        let contents = self.contents()
        guard !contents.isEmpty else { return }

        let needsSweep = config.countLimit < contents.count || config.sizeLimit < contents.totalSize
        guard needsSweep else { return }

        var totalSize = contents.totalSize
        var count = contents.count
        for content in contents.sorted(by: { $0.accessDate > $1.accessDate }) {
            if count <= config.countLimit, totalSize <= config.sizeLimit { break }
            totalSize -= content.fileSize
            count -= 1
            try? FileManager.default.removeItem(at: content.url)
        }
    }
}

extension DiskCache: DiskCaching {
    // MARK: - DiskCaching

    public func store(_ data: Data?, forKey key: String) {
        guard let data = data else { remove(forKey: key); return }
        lock.lock(); defer { lock.unlock() }
        guard let url = resolveCacheUrl(for: key) else { return }
        try? data.write(to: url)
    }

    public func remove(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        guard let url = resolveCacheUrl(for: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    public func removeAll() {
        lock.lock(); defer { lock.unlock() }
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    public subscript(_ key: String) -> Data? {
        get {
            guard let url = resolveCacheUrl(for: key) else { return nil }
            return try? Data(contentsOf: url)
        }
        set {
            store(newValue, forKey: key)
        }
    }
}
