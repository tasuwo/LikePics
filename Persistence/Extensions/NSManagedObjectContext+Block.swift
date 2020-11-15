//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

// swiftlint:disable untyped_error_in_catch

extension NSManagedObjectContext {
    func sync<T>(execute work: @escaping () throws -> T) throws -> T {
        var result: T?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)
        self.perform {
            do {
                result = try work()
            } catch let err {
                error = err
            }
            semaphore.signal()
        }
        semaphore.wait()

        if let error = error {
            throw error
        }

        // swiftlint:disable:next force_unwrapping
        return result!
    }
}
