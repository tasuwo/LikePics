//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain

public class NewImageQueryService {
    public var context: NSManagedObjectContext {
        willSet {
            self.context.perform { [weak self] in
                if self?.context.hasChanges == true {
                    self?.context.rollback()
                }
            }
        }
    }

    // MARK: - Lifecycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension NewImageQueryService: NewImageQueryServiceProtocol {
    public func read(having id: UUID) throws -> Data? {
        return try self.context.sync { [weak self] in
            let request: NSFetchRequest<Image> = Image.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try self?.context.fetch(request).first?.data
        }
    }
}
