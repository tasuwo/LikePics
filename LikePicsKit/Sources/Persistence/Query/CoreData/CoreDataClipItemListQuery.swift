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

class CoreDataClipItemListQuery: NSObject {
    typealias RequestFactory = () -> NSFetchRequest<Item>

    private let requestFactory: RequestFactory
    private var subject: CurrentValueSubject<[Domain.ClipItem], Error>
    private var controller: NSFetchedResultsController<Item>? {
        willSet {
            self.controller?.delegate = nil
            self.controller = nil
        }
    }

    // MARK: - Lifecycle

    init(requestFactory: @escaping RequestFactory, context: NSManagedObjectContext) throws {
        self.requestFactory = requestFactory

        let request = requestFactory()
        let currentClips = try context.fetch(request)
            .compactMap { $0.map(to: Domain.ClipItem.self) }

        self.subject = .init(currentClips)

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

extension CoreDataClipItemListQuery: NSFetchedResultsControllerDelegate {
    // MARK: - NSFetchedResultsControllerDelegate

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        controller.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            let clips: [Domain.ClipItem] = (snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>).itemIdentifiers
                .compactMap { controller.managedObjectContext.object(with: $0) as? Item }
                .compactMap { $0.map(to: Domain.ClipItem.self) }
            self.subject.send(clips)
        }
    }
}

extension CoreDataClipItemListQuery: ClipItemListQuery {
    // MARK: - ClipItemListQuery

    var items: CurrentValueSubject<[Domain.ClipItem], Error> {
        return self.subject
    }
}

extension CoreDataClipItemListQuery: ViewContextObserver {
    // MARK: - ViewContextObserver

    func didReplaced(context: NSManagedObjectContext) {
        self.setupQuery(for: context)
    }
}
