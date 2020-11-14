//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

public final class RelationshipKeyPathsObserver<ResultType: NSFetchRequestResult>: NSObject {
    private let keyPaths: Set<RelationshipKeyPath>
    private unowned let fetchedResultsController: FetchedResultsController<ResultType>

    private var updatedObjectIDs: Set<NSManagedObjectID> = []

    // MARK: - Lifecycle

    init?(keyPaths: Set<String>, fetchedResultsController: FetchedResultsController<ResultType>) {
        guard !keyPaths.isEmpty else { return nil }

        let relationships = fetchedResultsController.fetchRequest.entity!.relationshipsByName
        self.keyPaths = Set(keyPaths.map { keyPath in
            return RelationshipKeyPath(keyPath: keyPath, relationships: relationships)
        })
        self.fetchedResultsController = fetchedResultsController

        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidChangeNotification(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: fetchedResultsController.managedObjectContext)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidSaveNotification(notification:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: fetchedResultsController.managedObjectContext)
    }

    // MARK: - Methods

    @objc
    private func contextDidChangeNotification(notification: NSNotification) {
        guard let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
            let updatedObjectIDs = updatedObjects.updatedObjectIDs(for: keyPaths),
            !updatedObjectIDs.isEmpty
        else {
            return
        }
        self.updatedObjectIDs = self.updatedObjectIDs.union(updatedObjectIDs)
    }

    @objc
    private func contextDidSaveNotification(notification: NSNotification) {
        guard !self.updatedObjectIDs.isEmpty,
            let fetchedObjects = self.fetchedResultsController.fetchedObjects as? [NSManagedObject],
            !fetchedObjects.isEmpty
        else {
            return
        }
        fetchedObjects.forEach { object in
            guard self.updatedObjectIDs.contains(object.objectID) else { return }
            self.fetchedResultsController.managedObjectContext.refresh(object, mergeChanges: true)
        }
        self.updatedObjectIDs.removeAll()
    }
}
