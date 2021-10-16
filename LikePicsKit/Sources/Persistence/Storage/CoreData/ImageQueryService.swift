//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Smoothie

public class ImageQueryService {
    public var context: NSManagedObjectContext {
        willSet {
            self.context.perform { [weak self] in
                if self?.context.hasChanges == true {
                    self?.context.rollback()
                }
            }
        }
    }

    private let logger: Loggable

    // MARK: - Lifecycle

    public init(context: NSManagedObjectContext, logger: Loggable) {
        self.context = context
        self.logger = logger
    }
}

extension ImageQueryService: ImageQueryServiceProtocol {
    public func read(having id: UUID) throws -> Data? {
        return try self.context.sync { [weak self] in
            let request: NSFetchRequest<Image> = Image.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try self?.context.fetch(request).first?.data
        }
    }
}
