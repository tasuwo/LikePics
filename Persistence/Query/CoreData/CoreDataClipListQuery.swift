//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataClipListQuery: NSObject {
    private var subject: CurrentValueSubject<[Domain.Clip], Error>
    private let controller: NSFetchedResultsController<Clip>

    // MARK: - Lifecycle

    init(context: NSManagedObjectContext, request: NSFetchRequest<Clip>) throws {
        let currentClips = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Clip.self) }

        self.subject = .init(currentClips)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
    }
}

extension CoreDataClipListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        let clips: [Domain.Clip] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
            .compactMap { controller.managedObjectContext.object(with: $0) as? Clip }
            .compactMap { $0.map(to: Domain.Clip.self) }
        self.subject.send(clips)
    }
}

extension CoreDataClipListQuery: ClipListQuery {
    // MARK: - ClipListQuery

    var clips: CurrentValueSubject<[Domain.Clip], Error> {
        return self.subject
    }
}
