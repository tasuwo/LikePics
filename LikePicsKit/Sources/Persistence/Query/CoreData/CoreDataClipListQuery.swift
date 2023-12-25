//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
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

class CoreDataClipListQuery: NSObject {
    typealias RequestFactory = () -> NSFetchRequest<Clip>

    private let requestFactory: RequestFactory
    private var clipIds: Set<Domain.Clip.Identity>
    private var subject: CurrentValueSubject<[Domain.Clip], Error>
    private var controller: NSFetchedResultsController<Clip>? {
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
            .compactMap { $0.map(to: Domain.Clip.self) }

        self.clipIds = Set(currentClips.map({ $0.id }))
        self.subject = .init(currentClips)

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
            // ClipItemの更新を検知する
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> {
                for item in objects.compactMap({ $0 as? Item }) {
                    if let clip = item.clip, let clipId = clip.id, self.clipIds.contains(clipId) {
                        context.refresh(clip, mergeChanges: true)
                        return
                    }
                }
            }

            // ClipItemの削除を検知する
            if let objects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> {
                for item in objects.compactMap({ $0 as? Item }) {
                    if let clip = item.clip, let clipId = clip.id, self.clipIds.contains(clipId) {
                        context.refresh(clip, mergeChanges: true)
                        return
                    }
                }
            }
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
            self.clipIds = Set(clips.map { $0.id })
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
