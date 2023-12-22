//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// @mockable
public protocol MemoryCaching: AnyObject {
    #if canImport(UIKit)
    func insert(_ data: UIImage?, forKey key: String)
    #elseif canImport(AppKit)
    func insert(_ data: NSImage?, forKey key: String)
    #endif
    func remove(forKey key: String)
    func removeAll()
    #if canImport(UIKit)
    subscript(_ key: String) -> UIImage? { get set }
    #elseif canImport(AppKit)
    subscript(_ key: String) -> NSImage? { get set }
    #endif
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

    #if canImport(UIKit)
    private lazy var cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = config.costLimit
        cache.countLimit = config.countLimit
        cache.evictsObjectsWithDiscardedContent = false
        return cache
    }()

    #elseif canImport(AppKit)
    private lazy var cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.totalCostLimit = config.costLimit
        cache.countLimit = config.countLimit
        cache.evictsObjectsWithDiscardedContent = false
        return cache
    }()
    #endif

    private let config: Configuration

    // MARK: - Lifecycle

    public init(config: Configuration = .default) {
        self.config = config
    }
}

extension MemoryCache: MemoryCaching {
    // MARK: - MemoryCaching

    #if canImport(UIKit)
    public func insert(_ image: UIImage?, forKey key: String) {
        guard let image = image else { return remove(forKey: key) }
        cache.setObject(image, forKey: key as NSString)
    }

    #elseif canImport(AppKit)
    public func insert(_ image: NSImage?, forKey key: String) {
        guard let image = image else { return remove(forKey: key) }
        cache.setObject(image, forKey: key as NSString)
    }
    #endif

    public func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    public func removeAll() {
        cache.removeAllObjects()
    }

    #if canImport(UIKit)
    public subscript(key: String) -> UIImage? {
        get {
            return cache.object(forKey: key as NSString)
        }
        set {
            return insert(newValue, forKey: key)
        }
    }

    #elseif canImport(AppKit)
    public subscript(key: String) -> NSImage? {
        get {
            return cache.object(forKey: key as NSString)
        }
        set {
            return insert(newValue, forKey: key)
        }
    }
    #endif
}
