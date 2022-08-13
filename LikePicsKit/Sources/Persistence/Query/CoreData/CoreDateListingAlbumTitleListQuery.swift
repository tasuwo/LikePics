//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataListingAlbumTitleListQuery: NSObject {
    typealias RequestFactory = () -> NSFetchRequest<Album>

    private let requestFactory: RequestFactory
    private var subject: CurrentValueSubject<[Domain.ListingAlbumTitle], Error>
    private var controller: NSFetchedResultsController<Album>? {
        willSet {
            self.controller?.delegate = nil
            self.controller = nil
        }
    }

    // MARK: - Lifecycle

    init(requestFactory: @escaping RequestFactory, context: NSManagedObjectContext) throws {
        self.requestFactory = requestFactory

        let request = requestFactory()
        let currentAlbums = try context.fetch(request)
            .compactMap { $0.map(to: Domain.ListingAlbumTitle.self) }

        self.subject = .init(currentAlbums)

        super.init()

        self.setupQuery(for: context)
    }

    // MARK: - Methods

    private func setupQuery(for context: NSManagedObjectContext) {
        context.perform { [weak self] in
            guard let self = self else { return }

            self.controller = NSFetchedResultsController(fetchRequest: self.requestFactory(),
                                                         managedObjectContext: context,
                                                         sectionNameKeyPath: nil,
                                                         cacheName: nil)
            self.controller?.delegate = self

            do {
                try self.controller?.performFetch()
            } catch {
                self.subject.send(completion: .failure(error))
            }
        }
    }
}

extension CoreDataListingAlbumTitleListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let albums: [Domain.ListingAlbumTitle] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Album }
                .compactMap { $0.map(to: Domain.ListingAlbumTitle.self) }
            self.subject.send(albums)
        }
    }
}

extension CoreDataListingAlbumTitleListQuery: ListingAlbumTitleListQuery {
    // MARK: - ListingAlbumListQuery

    var albums: CurrentValueSubject<[Domain.ListingAlbumTitle], Error> {
        return subject
    }
}

extension CoreDataListingAlbumTitleListQuery: ViewContextObserver {
    // MARK: - ViewContextObserver

    func didReplaced(context: NSManagedObjectContext) {
        setupQuery(for: context)
    }
}
