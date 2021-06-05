//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataListingAlbumListQuery: NSObject {
    typealias RequestFactory = () -> NSFetchRequest<Album>

    private let requestFactory: RequestFactory
    private var albumIds: Set<Domain.ListingAlbum.Identity>
    private var subject: CurrentValueSubject<[Domain.ListingAlbum], Error>
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
            .compactMap { $0.map(to: Domain.ListingAlbum.self) }

        self.albumIds = Set(currentAlbums.map({ $0.id }))
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

        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidChangeNotification(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }

    @objc
    private func contextDidChangeNotification(notification: NSNotification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        context.perform { [weak self] in
            guard let self = self else { return }
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
                // AlbumItemの更新を検知する
                for albumItem in objects.compactMap({ $0 as? AlbumItem }) {
                    if let album = albumItem.album, let albumId = album.id, self.albumIds.contains(albumId) {
                        context.refresh(album, mergeChanges: true)
                        return
                    }
                }
            }
        }
    }
}

extension CoreDataListingAlbumListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let albums: [Domain.ListingAlbum] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Album }
                .compactMap { $0.map(to: Domain.ListingAlbum.self) }
            self.albumIds = Set(albums.map { $0.id })
            self.subject.send(albums)
        }
    }
}

extension CoreDataListingAlbumListQuery: ListingAlbumListQuery {
    // MARK: - ListingAlbumListQuery

    var albums: CurrentValueSubject<[Domain.ListingAlbum], Error> {
        return subject
    }
}

extension CoreDataListingAlbumListQuery: ViewContextObserver {
    // MARK: - ViewContextObserver

    func didReplaced(context: NSManagedObjectContext) {
        setupQuery(for: context)
    }
}
