//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain

public class NewImageQueryService {
    private let context: NSManagedObjectContext

    // MARK: - Lifecycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension NewImageQueryService: NewImageQueryServiceProtocol {
    public func read(having id: UUID) throws -> Data? {
        return try self.context.sync { [weak self] in
            let request = NSFetchRequest<Image>(entityName: "Image")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try self?.context.fetch(request).first?.data
        }
    }
}
