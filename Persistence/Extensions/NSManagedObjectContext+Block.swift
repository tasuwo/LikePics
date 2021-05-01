//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

// swiftlint:disable untyped_error_in_catch

extension NSManagedObjectContext {
    func sync<T>(execute work: @escaping () throws -> T) throws -> T {
        var result: T?
        var error: Error?

        self.performAndWait {
            do {
                result = try work()
            } catch let err {
                error = err
            }
        }

        if let error = error {
            throw error
        }

        // swiftlint:disable:next force_unwrapping
        return result!
    }

    func sync<T>(execute work: @escaping () -> T) -> T {
        var result: T?

        self.performAndWait {
            result = work()
        }

        // swiftlint:disable:next force_unwrapping
        return result!
    }
}
