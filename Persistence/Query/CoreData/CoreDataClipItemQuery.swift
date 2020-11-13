//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataClipItemQuery: NSObject {
    private let id: Domain.ClipItem.Identity
    private var subject: CurrentValueSubject<Domain.ClipItem, Error>
    private let controller: NSFetchedResultsController<Item>

    // MARK: - Lifecycle

    init?(id: Domain.ClipItem.Identity, context: NSManagedObjectContext) throws {
        self.id = id

        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]

        guard let currentItem = try context
            .fetch(request)
            .compactMap({ $0.map(to: Domain.ClipItem.self) })
            .first
        else {
            return nil
        }

        self.subject = .init(currentItem)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
        try self.controller.performFetch()
    }
}

extension CoreDataClipItemQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        let item: Domain.ClipItem? = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
            .compactMap { controller.managedObjectContext.object(with: $0) as? Item }
            .compactMap { $0.map(to: Domain.ClipItem.self) }
            .first(where: { $0.identity == self.id })
        if let item = item {
            self.subject.send(item)
        }
    }
}

extension CoreDataClipItemQuery: ClipItemQuery {
    // MARK: - ClipItemQuery

    var clipItem: CurrentValueSubject<Domain.ClipItem, Error> {
        return self.subject
    }
}
