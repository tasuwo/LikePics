//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataClipListQuery: NSObject {
    enum Context {
        case clipsRequest(controller: NSFetchedResultsController<Clip>)
        case tagRelatedClipsRequest(tagId: Domain.Tag.Identity, NSFetchedResultsController<Tag>)
    }

    private let context: Context
    private var subject: CurrentValueSubject<[Domain.Clip], Error>

    // MARK: - Lifecycle

    init(request: NSFetchRequest<Clip>, context: NSManagedObjectContext) throws {
        let currentClips = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Clip.self) }

        self.subject = .init(currentClips)
        let controller = NSFetchedResultsController(fetchRequest: request,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        self.context = .clipsRequest(controller: controller)

        super.init()

        controller.delegate = self
        try controller.performFetch()
    }

    init?(id: Domain.Tag.Identity, context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        guard let currentTag = try context.fetch(request).first else {
            return nil
        }

        let currentClips = currentTag.clips?.allObjects
            .compactMap { $0 as? Clip }
            .compactMap { $0.map(to: Domain.Clip.self) } ?? []

        self.subject = .init(currentClips)
        let controller = NSFetchedResultsController(fetchRequest: request,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        self.context = .tagRelatedClipsRequest(tagId: id, controller)

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
        switch self.context {
        case .clipsRequest:
            let clips: [Domain.Clip] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Clip }
                .compactMap { $0.map(to: Domain.Clip.self) }
            self.subject.send(clips)

        case let .tagRelatedClipsRequest(tagId: id, _):
            let tag: Tag? = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Tag }
                .first(where: { $0.id?.uuidString == id })
            if let tag = tag {
                let clips = tag.clips?.allObjects
                    .compactMap { $0 as? Clip }
                    .compactMap { $0.map(to: Domain.Clip.self) } ?? []
                self.subject.send(clips)
            }
        }
    }
}

extension CoreDataClipListQuery: ClipListQuery {
    // MARK: - ClipListQuery

    var clips: CurrentValueSubject<[Domain.Clip], Error> {
        return self.subject
    }
}
