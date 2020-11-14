//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CoreData
import Domain
import UIKit

class CoreDataClipQuery: NSObject {
    private let objectId: NSManagedObjectID
    private var subject: CurrentValueSubject<Domain.Clip, Error>

    // MARK: - Lifecycle

    init?(id: Domain.Clip.Identity, context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<Clip>(entityName: "Clip")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let clip = try context.fetch(request).first,
            let domainClip = clip.map(to: Domain.Clip.self)
        else {
            return nil
        }

        self.objectId = clip.objectID
        self.subject = .init(domainClip)

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
                objects.compactMap({ $0 as? Clip }).contains(where: { $0.objectID == self.objectId })
            {
                self.subject.send(completion: .finished)
                return
            }
            if let objects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                let object = objects.compactMap({ $0 as? Clip }).first(where: { $0.objectID == self.objectId }),
                let clip = object.map(to: Domain.Clip.self)
            {
                self.subject.send(clip)
                return
            }
            if let objects = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject>,
                let object = objects.compactMap({ $0 as? Clip }).first(where: { $0.objectID == self.objectId }),
                let clip = object.map(to: Domain.Clip.self)
            {
                self.subject.send(clip)
                return
            }
        }
    }
}

extension CoreDataClipQuery: ClipQuery {
    // MARK: - ClipQuery

    var clip: CurrentValueSubject<Domain.Clip, Error> {
        return self.subject
    }
}
