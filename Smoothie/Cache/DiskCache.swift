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
            sizeLimit: 1024 * 1024 * 150, // 150MB
            countLimit: 1000,
            fileNameResolver: { $0.sha256() }
        )

        public let sizeLimit: Int
        public let countLimit: Int
        public let fileNameResolver: (_ key: String) -> String?

        public init(sizeLimit: Int, countLimit: Int, fileNameResolver: @escaping ((_ key: String) -> String?) = { $0.sha256() }) {
            self.sizeLimit = sizeLimit
            self.countLimit = countLimit
            self.fileNameResolver = fileNameResolver
        }
    }

    // MARK: - Properties

    private let url: URL
    private let config: Configuration
    private let ioQueue = DispatchQueue(label: "net.tasuwo.TBox.Domain.DiskCache.IOQueue", target: .global(qos: .utility))

    // MARK: Sweep

    public var initialSweepDelay: TimeInterval = 10
    public var sweepInterval: TimeInterval = 30

    // MARK: Staging

    public var flushInterval: TimeInterval = 1
    private var isFlushScheduled = false
    private let stagingLock = NSLock()
    private var staging: Staging

    // MARK: - Initializers

    public init(path: URL, config: Configuration = .default) throws {
        self.url = path
        self.config = config
        self.staging = Staging()
        try self.setup()
    }

    // MARK: - Methods

    private func setup() throws {
        try createDirectoryIfNeeded(at: url)
        ioQueue.asyncAfter(deadline: .now() + initialSweepDelay) { [weak self] in
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
        ioQueue.asyncAfter(deadline: .now() + sweepInterval) { [weak self] in
            self?.performAndScheduleSweep()
        }
    }

    private func performSweep() {
        dispatchPrecondition(condition: .onQueue(ioQueue))

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

// MARK: - Staging

extension DiskCache {
    private struct Staging {
        enum Change: Equatable {
            case add(Data)
            case remove
        }

        private(set) var changes: [String: Change] = [:]
        private(set) var shouldRemoveAll = false
        private(set) var isFlushNeeded = false

        func change(for key: String) -> Change? {
            changes[key]
        }

        mutating func remove(key: String) {
            changes[key] = .remove
            isFlushNeeded = true
        }

        mutating func add(_ data: Data, for key: String) {
            changes[key] = .add(data)
            isFlushNeeded = true
        }

        mutating func removeAll() {
            shouldRemoveAll = true
            isFlushNeeded = true
        }

        mutating func flushed() {
            changes = [:]
            shouldRemoveAll = false
            isFlushNeeded = false
        }
    }

    private func scheduleFlushNonAtomically() {
        guard !isFlushScheduled else { return }
        isFlushScheduled = true
        ioQueue.asyncAfter(deadline: .now() + flushInterval) { [weak self] in
            self?.performFlush()
        }
    }

    private func performFlush() {
        dispatchPrecondition(condition: .onQueue(ioQueue))

        let stagingSnapshot: Staging
        stagingLock.lock()
        stagingSnapshot = staging
        staging.flushed()
        stagingLock.unlock()

        autoreleasepool {
            if stagingSnapshot.shouldRemoveAll {
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }

            for (key, change) in stagingSnapshot.changes {
                guard let url = resolveCacheUrl(for: key) else { continue }

                switch change {
                case let .add(data):
                    try? data.write(to: url)

                case .remove:
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }

        stagingLock.lock()
        isFlushScheduled = false
        if staging.isFlushNeeded {
            scheduleFlushNonAtomically()
        }
        stagingLock.unlock()
    }
}

extension DiskCache: DiskCaching {
    // MARK: - DiskCaching

    public func store(_ data: Data?, forKey key: String) {
        guard let data = data else { remove(forKey: key); return }
        stagingLock.lock(); defer { stagingLock.unlock() }
        staging.add(data, for: key)
        scheduleFlushNonAtomically()
    }

    public func remove(forKey key: String) {
        stagingLock.lock(); defer { stagingLock.unlock() }
        staging.remove(key: key)
        scheduleFlushNonAtomically()
    }

    public func removeAll() {
        stagingLock.lock(); defer { stagingLock.unlock() }
        staging.removeAll()
        scheduleFlushNonAtomically()
    }

    public subscript(_ key: String) -> Data? {
        get {
            let change: Staging.Change?
            stagingLock.lock()
            change = staging.change(for: key)
            stagingLock.unlock()

            switch change {
            case let .add(data):
                return data

            case .remove:
                return nil

            case .none:
                break
            }

            guard let url = resolveCacheUrl(for: key) else {
                return nil
            }

            return try? Data(contentsOf: url)
        }
        set {
            store(newValue, forKey: key)
        }
    }
}
