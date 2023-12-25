//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain

class CoreDataAlbumQuery: NSObject {
    private let objectId: NSManagedObjectID
    private var subject: CurrentValueSubject<Domain.Album, Error>

    // MARK: - Lifecycle

    init?(id: Domain.Album.Identity, context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let album = try context.fetch(request).first,
              let domainAlbum = album.map(to: Domain.Album.self)
        else {
            return nil
        }

        self.objectId = album.objectID
        self.subject = .init(domainAlbum)

        super.init()

        self.setupQuery(for: context)
    }

    // MARK: - Methods

    private func setupQuery(for context: NSManagedObjectContext) {
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name.NSManagedObjectContextObjectsDidChange,
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
            if let objects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>,
               objects.compactMap({ $0 as? Album }).contains(where: { $0.objectID == self.objectId })
            {
                self.subject.send(completion: .finished)
                return
            }
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>,
               let object = objects.compactMap({ $0 as? Album }).first(where: { $0.objectID == self.objectId }),
               let album = object.map(to: Domain.Album.self)
            {
                self.subject.send(album)
                return
            }

            // AlbumItemの更新を検知する
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
                for albumItem in objects.compactMap({ $0 as? AlbumItem }) {
                    if let album = albumItem.album, album.objectID == self.objectId {
                        context.refresh(album, mergeChanges: true)
                        return
                    }
                }
            }

            // Clipの更新を検知する
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
                for clip in objects.compactMap({ $0 as? Clip }) {
                    if let albumItem = clip.albumItem?
                        .allObjects
                        .compactMap({ $0 as? AlbumItem })
                        .first(where: { $0.album?.objectID == self.objectId }),
                        let album = albumItem.album
                    {
                        context.refresh(album, mergeChanges: true)
                        return
                    }
                }
            }
        }
    }
}

extension CoreDataAlbumQuery: AlbumQuery {
    // MARK: - AlbumQuery

    var album: CurrentValueSubject<Domain.Album, Error> {
        return self.subject
    }
}

extension CoreDataAlbumQuery: ViewContextObserver {
    // MARK: - ViewContextObserver

    func didReplaced(context: NSManagedObjectContext) {
        self.setupQuery(for: context)
    }
}
