///
/// @Generated by Mockolo
///

import Foundation
import UIKit

@testable import Smoothie

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

public class DiskCachingMock: DiskCaching {
    public init() {}

    public private(set) var storeCallCount = 0
    public var storeHandler: ((Data?, String) -> Void)?
    public func store(_ data: Data?, forKey key: String) {
        storeCallCount += 1
        if let storeHandler = storeHandler {
            storeHandler(data, key)
        }
    }

    public private(set) var removeCallCount = 0
    public var removeHandler: ((String) -> Void)?
    public func remove(forKey key: String) {
        removeCallCount += 1
        if let removeHandler = removeHandler {
            removeHandler(key)
        }
    }

    public private(set) var removeAllCallCount = 0
    public var removeAllHandler: (() -> Void)?
    public func removeAll() {
        removeAllCallCount += 1
        if let removeAllHandler = removeAllHandler {
            removeAllHandler()
        }
    }

    public private(set) var existsCallCount = 0
    public var existsHandler: ((String) -> (Bool))?
    public func exists(forKey: String) -> Bool {
        existsCallCount += 1
        if let existsHandler = existsHandler {
            return existsHandler(forKey)
        }
        return false
    }

    public private(set) var subscriptCallCount = 0
    public var subscriptHandler: ((String) -> (Data?))?
    public subscript(_ key: String) -> Data? {
        get {
            subscriptCallCount += 1
            if let subscriptHandler = subscriptHandler {
                return subscriptHandler(key)
            }
            return nil
        }
        set {}
    }
}

public class MemoryCachingMock: MemoryCaching {
    public init() {}

    public private(set) var removeCallCount = 0
    public var removeHandler: ((String) -> Void)?
    public func remove(forKey key: String) {
        removeCallCount += 1
        if let removeHandler = removeHandler {
            removeHandler(key)
        }
    }

    public private(set) var removeAllCallCount = 0
    public var removeAllHandler: (() -> Void)?
    public func removeAll() {
        removeAllCallCount += 1
        if let removeAllHandler = removeAllHandler {
            removeAllHandler()
        }
    }

    #if canImport(UIKit)

    public private(set) var insertCallCount = 0
    public var insertHandler: ((UIImage?, String) -> Void)?
    public func insert(_ data: UIImage?, forKey key: String) {
        insertCallCount += 1
        if let insertHandler = insertHandler {
            insertHandler(data, key)
        }
    }

    public private(set) var subscriptCallCount = 0
    public var subscriptHandler: ((String) -> (UIImage?))?
    public subscript(_ key: String) -> UIImage? {
        get {
            subscriptCallCount += 1
            if let subscriptHandler = subscriptHandler {
                return subscriptHandler(key)
            }
            return nil
        }
        set {}
    }
    #endif
    #if canImport(AppKit)

    public private(set) var insertCallCount = 0
    public var insertHandler: ((NSImage?, String) -> Void)?
    public func insert(_ data: NSImage?, forKey key: String) {
        insertCallCount += 1
        if let insertHandler = insertHandler {
            insertHandler(data, key)
        }
    }

    public private(set) var subscriptCallCount = 0
    public var subscriptHandler: ((String) -> (NSImage?))?
    public subscript(_ key: String) -> NSImage? {
        get {
            subscriptCallCount += 1
            if let subscriptHandler = subscriptHandler {
                return subscriptHandler(key)
            }
            return nil
        }
        set {}
    }
    #endif
}
