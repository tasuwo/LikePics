//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataAlbumListQuery: NSObject {
    private var subject: CurrentValueSubject<[Domain.Album], Error>
    private let controller: NSFetchedResultsController<Album>

    // MARK: - Lifecycle

    init(request: NSFetchRequest<Album>, context: NSManagedObjectContext) throws {
        let currentAlbums = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Album.self) }

        self.subject = .init(currentAlbums)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
        try self.controller.performFetch()
    }
}

extension CoreDataAlbumListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let albums: [Domain.Album] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Album }
                .compactMap { $0.map(to: Domain.Album.self) }
            self.subject.send(albums)
        }
    }
}

extension CoreDataAlbumListQuery: AlbumListQuery {
    // MARK: - AlbumListQuery

    var albums: CurrentValueSubject<[Domain.Album], Error> {
        return self.subject
    }
}
