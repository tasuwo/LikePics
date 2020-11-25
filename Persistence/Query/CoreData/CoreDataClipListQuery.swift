//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataClipListQuery: NSObject {
    private let request: NSFetchRequest<Clip>
    private var subject: CurrentValueSubject<[Domain.Clip], Error>
    private var controller: NSFetchedResultsController<Clip>?

    // MARK: - Lifecycle

    init(request: NSFetchRequest<Clip>, context: NSManagedObjectContext) throws {
        let currentClips = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Clip.self) }

        self.request = request
        self.subject = .init(currentClips)

        super.init()

        self.setupQuery(for: context)
    }

    // MARK: - Methods

    private func setupQuery(for context: NSManagedObjectContext) {
        self.controller = NSFetchedResultsController(fetchRequest: self.request,
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

extension CoreDataClipListQuery: ViewContextObserver {
    // MARK: - ViewContextObserver

    func didReplaced(context: NSManagedObjectContext) {
        self.setupQuery(for: context)
    }
}
