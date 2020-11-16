//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain

public class NewImageStorage {
    private let context: NSManagedObjectContext

    // MARK: - Lifecycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension NewImageStorage: NewImageStorageProtocol {
    // MARK: Transaction

    public var isInTransaction: Bool {
        return self.context.hasChanges
    }

    public func beginTransaction() throws {
        // NOP
    }

    public func commitTransaction() throws {
        try self.context.save()
    }

    public func cancelTransactionIfNeeded() throws {
        self.context.rollback()
    }

    // MARK: Create

    public func create(_ image: Data, id: UUID) throws {
        // swiftlint:disable:next force_cast
        let newImage = NSEntityDescription.insertNewObject(forEntityName: "Image", into: self.context) as! Image
        newImage.id = id
        newImage.data = image
    }

    // MARK: Delete

    public func delete(having id: ImageContainer.Identity) throws {
        let request = NSFetchRequest<Image>(entityName: "Image")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let image = try self.context.fetch(request).first else { return }
        self.context.delete(image)
    }

    // MARK: Read

    public func exists(having id: ImageContainer.Identity) throws -> Bool {
        let request = NSFetchRequest<Image>(entityName: "Image")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try self.context.count(for: request) > 0
    }
}