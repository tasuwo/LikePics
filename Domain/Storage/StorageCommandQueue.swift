//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol StorageCommandQueue {
    func sync<T>(_ block: @escaping () -> T) -> T
    func sync<T>(_ block: @escaping () throws -> T) throws -> T
    func async(_ block: @escaping () -> Void)
}
