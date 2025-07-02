//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

class CoreDataListingAlbumTitleListForClipQuery: NSObject {
    typealias RequestFactory = () -> NSFetchRequest<AlbumItem>

    private let requestFactory: RequestFactory
    private var subject: CurrentValueSubject<[Domain.ListingAlbumTitle], Error>
    private var controller: NSFetchedResultsController<AlbumItem>? {
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
            .compactMap { $0.album?.map(to: Domain.ListingAlbumTitle.self) }

        self.subject = .init(currentAlbums)

        super.init()

        self.setupQuery(for: context)
    }

    // MARK: - Methods

    private func setupQuery(for context: NSManagedObjectContext) {
        context.perform { [weak self] in
            guard let self = self else { return }

            self.controller = NSFetchedResultsController(
                fetchRequest: self.requestFactory(),
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            self.controller?.delegate = self

            do {
                try self.controller?.performFetch()
            } catch {
                self.subject.send(completion: .failure(error))
            }
        }
    }
}

extension CoreDataListingAlbumTitleListForClipQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let albums: [Domain.ListingAlbumTitle] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? AlbumItem }
                .compactMap { $0.album?.map(to: Domain.ListingAlbumTitle.self) }
            self.subject.send(albums)
        }
    }
}

extension CoreDataListingAlbumTitleListForClipQuery: ListingAlbumTitleListQuery {
    // MARK: - ListingAlbumListQuery

    var albums: CurrentValueSubject<[Domain.ListingAlbumTitle], Error> {
        return subject
    }
}

extension CoreDataListingAlbumTitleListForClipQuery: ViewContextObserver {
    // MARK: - ViewContextObserver

    func didReplaced(context: NSManagedObjectContext) {
        setupQuery(for: context)
    }
}
