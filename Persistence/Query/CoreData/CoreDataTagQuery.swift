//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataTagQuery: NSObject {
    private let objectId: NSManagedObjectID
    private var subject: CurrentValueSubject<Domain.Tag, Error>

    // MARK: - Lifecycle

    init?(id: Domain.Tag.Identity, context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let tag = try context.fetch(request).first,
            let domainTag = tag.map(to: Domain.Tag.self)
        else {
            return nil
        }

        self.objectId = tag.objectID
        self.subject = .init(domainTag)

        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidChangeNotification(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }

    // MARK: - Methods

    @objc
    private func contextDidChangeNotification(notification: NSNotification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        context.perform {
            if let objects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>,
                objects.compactMap({ $0 as? Tag }).contains(where: { $0.objectID == self.objectId })
            {
                self.subject.send(completion: .finished)
                return
            }
            if let objects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                let object = objects.compactMap({ $0 as? Tag }).first(where: { $0.objectID == self.objectId }),
                let tag = object.map(to: Domain.Tag.self)
            {
                self.subject.send(tag)
                return
            }
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>,
                let object = objects.compactMap({ $0 as? Tag }).first(where: { $0.objectID == self.objectId }),
                let tag = object.map(to: Domain.Tag.self)
            {
                self.subject.send(tag)
                return
            }
        }
    }
}

extension CoreDataTagQuery: TagQuery {
    // MARK: - TagQuery

    var tag: CurrentValueSubject<Domain.Tag, Error> {
        return self.subject
    }
}
