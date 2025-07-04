//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public class TransitionLock {
    let lock = NSLock()

    var transitionId: UUID?

    public var isFree: Bool {
        lock.lock()
        defer { lock.unlock() }
        return transitionId == nil
    }

    public init() {}

    @discardableResult
    func takeLock(_ id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard transitionId == nil else { return false }
        transitionId = id
        return true
    }

    @discardableResult
    func isLocked(by id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return transitionId == id
    }

    func releaseLock() {
        lock.lock()
        defer { lock.unlock() }
        transitionId = nil
    }
}
