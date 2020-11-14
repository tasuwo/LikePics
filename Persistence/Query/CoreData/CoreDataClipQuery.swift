//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataClipQuery: NSObject {
    private let id: Domain.Clip.Identity
    private var subject: CurrentValueSubject<Domain.Clip, Error>
    private let controller: NSFetchedResultsController<Clip>

    // MARK: - Lifecycle

    init?(id: Domain.Clip.Identity, context: NSManagedObjectContext) throws {
        self.id = id

        let request = NSFetchRequest<Clip>(entityName: "Clip")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Clip.createdDate, ascending: true)]

        guard let currentClip = try context
            .fetch(request)
            .compactMap({ $0.map(to: Domain.Clip.self) })
            .first
        else {
            return nil
        }

        self.subject = .init(currentClip)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
        try self.controller.performFetch()
    }
}

extension CoreDataClipQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        controller.managedObjectContext.perform {
            let clip: Domain.Clip? = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Clip }
                .compactMap { $0.map(to: Domain.Clip.self) }
                .first(where: { $0.identity == self.id })
            if let clip = clip {
                self.subject.send(clip)
            }
        }
    }
}

extension CoreDataClipQuery: ClipQuery {
    // MARK: - ClipQuery

    var clip: CurrentValueSubject<Domain.Clip, Error> {
        return self.subject
    }
}