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

    init(request: NSFetchRequest<Clip>, context: NSManagedObjectContext) throws {
        let currentClips = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Clip.self) }

        self.subject = .init(currentClips)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        controller.delegate = self
        try controller.performFetch()
    }
}

extension CoreDataClipListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let clips: [Domain.Clip] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Clip }
                .compactMap { $0.map(to: Domain.Clip.self) }
            self.subject.send(clips)
        }
    }
}

extension CoreDataClipListQuery: ClipListQuery {
    // MARK: - ClipListQuery

    var clips: CurrentValueSubject<[Domain.Clip], Error> {
        return self.subject
    }
}
