//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataAlbumQuery: NSObject {
    private let id: Domain.Album.Identity
    private var subject: CurrentValueSubject<Domain.Album, Error>
    private let controller: NSFetchedResultsController<Album>

    // MARK: - Lifecycle

    init?(id: Domain.Album.Identity, context: NSManagedObjectContext) throws {
        self.id = id

        let request = NSFetchRequest<Album>(entityName: "Album")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]

        guard let currentAlbum = try context
            .fetch(request)
            .compactMap({ $0.map(to: Domain.Album.self) })
            .first
        else {
            return nil
        }

        self.subject = .init(currentAlbum)
        self.controller = NSFetchedResultsController(fetchRequest: request,
                                                     managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)

        super.init()

        self.controller.delegate = self
    }
}

extension CoreDataAlbumQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        let album: Domain.Album? = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
            .compactMap { controller.managedObjectContext.object(with: $0) as? Album }
            .compactMap { $0.map(to: Domain.Album.self) }
            .first(where: { $0.identity == self.id })
        if let album = album {
            self.subject.send(album)
        }
    }
}

extension CoreDataAlbumQuery: AlbumQuery {
    // MARK: - AlbumQuery

    var album: CurrentValueSubject<Domain.Album, Error> {
        return self.subject
    }
}
