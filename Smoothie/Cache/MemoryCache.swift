//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol MemoryCaching: AnyObject {
    func insert(_ data: Data?, forKey key: String)
    func remove(forKey key: String)
    func removeAll()
    subscript(_ key: String) -> Data? { get set }
}

public final class MemoryCache {
    public struct Configuration {
        public static let `default` = Configuration(
            costLimit: Int.max,
            countLimit: Int.max
        )
        public let costLimit: Int
        public let countLimit: Int
    }

    private lazy var cache: NSCache<NSString, AnyObject> = {
        let cache = NSCache<NSString, AnyObject>()
        cache.totalCostLimit = config.costLimit
        cache.countLimit = config.countLimit
        return cache
    }()

    private let lock = NSLock()
    private let config: Configuration

    // MARK: - Lifecycle

    public init(config: Configuration = .default) {
        self.config = config
    }
}

extension MemoryCache: MemoryCaching {
    // MARK: - MemoryCaching

    public func insert(_ data: Data?, forKey key: String) {
        guard let data = data else { return remove(forKey: key) }
        lock.lock(); defer { lock.unlock() }
        cache.setObject(data as AnyObject, forKey: key as NSString)
    }

    public func remove(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        cache.removeObject(forKey: key as NSString)
    }

    public func removeAll() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAllObjects()
    }

    public subscript(key: String) -> Data? {
        get {
            return cache.object(forKey: key as NSString) as? Data
        }
        set {
            return insert(newValue, forKey: key)
        }
    }
}
