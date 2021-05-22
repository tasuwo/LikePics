//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol TemporariesPersistServiceObserver: AnyObject {
    func temporariesPersistService(_ service: TemporariesPersistService, didStartThe index: Int, outOf count: Int)
}

/// @mockable
public protocol TemporariesPersistServiceProtocol {
    func set(observer: TemporariesPersistServiceObserver)
    func persistIfNeeded() -> Bool
}
