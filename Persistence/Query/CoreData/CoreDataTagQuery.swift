//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataTagQuery: NSObject {
    private let id: Domain.Tag.Identity
    private var subject: CurrentValueSubject<Domain.Tag, Error>
    private let controller: NSFetchedResultsController<Tag>

    // MARK: - Lifecycle

    init(context: NSManagedObjectContext, id: Domain.Tag.Identity) throws {
        self.id = id

        let request = NSFetchRequest<Tag>(entityName: "Tag")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let currentTag = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Tag.self) }
            // TODO:
            .first!

        self.subject = .init(currentTag)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
    }
}

extension CoreDataTagQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        let tag: Domain.Tag? = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
            .compactMap { controller.managedObjectContext.object(with: $0) as? Tag }
            .compactMap { $0.map(to: Domain.Tag.self) }
            .first(where: { $0.identity == self.id })
        if let tag = tag {
            self.subject.send(tag)
        }
    }
}

extension CoreDataTagQuery: TagQuery {
    // MARK: - TagQuery

    var tag: CurrentValueSubject<Domain.Tag, Error> {
        return self.subject
    }
}
