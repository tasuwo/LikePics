//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol MemoryCaching: AnyObject {
    func insert(_ data: UIImage?, forKey key: String)
    func remove(forKey key: String)
    func removeAll()
    subscript(_ key: String) -> UIImage? { get set }
}

public final class MemoryCache {
    public struct Configuration {
        public static let `default` = Configuration(
            costLimit: Int(Self.defaultCostLimit()),
            countLimit: Int.max
        )

        public let costLimit: Int
        public let countLimit: Int

        public init(costLimit: Int, countLimit: Int) {
            self.costLimit = costLimit
            self.countLimit = countLimit
        }

        public static func defaultCostLimit() -> UInt64 {
            let totalMemory = ProcessInfo.processInfo.physicalMemory
            return totalMemory / 4
        }
    }

    private lazy var cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = config.costLimit
        cache.countLimit = config.countLimit
        cache.evictsObjectsWithDiscardedContent = false
        return cache
    }()

    private let config: Configuration

    // MARK: - Lifecycle

    public init(config: Configuration = .default) {
        self.config = config
    }
}

extension MemoryCache: MemoryCaching {
    // MARK: - MemoryCaching

    public func insert(_ image: UIImage?, forKey key: String) {
        guard let image = image else { return remove(forKey: key) }
        cache.setObject(image, forKey: key as NSString)
    }

    public func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    public func removeAll() {
        cache.removeAllObjects()
    }

    public subscript(key: String) -> UIImage? {
        get {
            return cache.object(forKey: key as NSString)
        }
        set {
            return insert(newValue, forKey: key)
        }
    }
}
