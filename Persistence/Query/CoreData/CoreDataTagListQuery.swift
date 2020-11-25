//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataTagListQuery: NSObject {
    private let request: NSFetchRequest<Tag>
    private var subject: CurrentValueSubject<[Domain.Tag], Error>
    private var controller: NSFetchedResultsController<Tag>?

    // MARK: - Lifecycle

    init(request: NSFetchRequest<Tag>, context: NSManagedObjectContext) throws {
        let currentTags = try context.fetch(request)
            .compactMap { $0.map(to: Domain.Tag.self) }

        self.request = request
        self.subject = .init(currentTags)

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

extension CoreDataTagListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference)
    {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let tags: [Domain.Tag] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Tag }
                .compactMap { $0.map(to: Domain.Tag.self) }
            self.subject.send(tags)
        }
    }
}

extension CoreDataTagListQuery: TagListQuery {
    // MARK: - ClipListQuery

    var tags: CurrentValueSubject<[Domain.Tag], Error> {
        return self.subject
    }
}

extension CoreDataTagListQuery: ViewContextObserver {
    // MARK: - ViewContextObserver

    func didReplaced(context: NSManagedObjectContext) {
        self.setupQuery(for: context)
    }
}
