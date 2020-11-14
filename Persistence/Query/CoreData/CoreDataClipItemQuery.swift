//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataClipItemQuery: NSObject {
    private let objectId: NSManagedObjectID
    private var subject: CurrentValueSubject<Domain.ClipItem, Error>

    // MARK: - Lifecycle

    init?(id: Domain.ClipItem.Identity, context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let item = try context.fetch(request).first,
            let domainItem = item.map(to: Domain.ClipItem.self)
        else {
            return nil
        }

        self.objectId = item.objectID
        self.subject = .init(domainItem)

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
                objects.compactMap({ $0 as? Item }).contains(where: { $0.objectID == self.objectId })
            {
                self.subject.send(completion: .finished)
                return
            }
            if let objects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                let object = objects.compactMap({ $0 as? Item }).first(where: { $0.objectID == self.objectId }),
                let item = object.map(to: Domain.ClipItem.self)
            {
                self.subject.send(item)
                return
            }
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>,
                let object = objects.compactMap({ $0 as? Item }).first(where: { $0.objectID == self.objectId }),
                let item = object.map(to: Domain.ClipItem.self)
            {
                self.subject.send(item)
                return
            }
        }
    }
}

extension CoreDataClipItemQuery: ClipItemQuery {
    // MARK: - ClipItemQuery

    var clipItem: CurrentValueSubject<Domain.ClipItem, Error> {
        return self.subject
    }
}
