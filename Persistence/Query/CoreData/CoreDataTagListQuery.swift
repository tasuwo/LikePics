//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataTagListQuery: NSObject {
    private var subject: CurrentValueSubject<[Domain.Tag], Error>
    private let controller: NSFetchedResultsController<Tag>

    // MARK: - Lifecycle

    init(request: NSFetchRequest<Tag>, context: NSManagedObjectContext) throws {
        let currentTags = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Tag.self) }

        self.subject = .init(currentTags)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
    }
}

extension CoreDataTagListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        let tags: [Domain.Tag] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
            .compactMap { controller.managedObjectContext.object(with: $0) as? Tag }
            .compactMap { $0.map(to: Domain.Tag.self) }
        self.subject.send(tags)
    }
}

extension CoreDataTagListQuery: TagListQuery {
    // MARK: - ClipListQuery

    var tags: CurrentValueSubject<[Domain.Tag], Error> {
        return self.subject
    }
}
