//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Foundation

class FetchedResultsController<ResultType: NSFetchRequestResult>: NSFetchedResultsController<NSFetchRequestResult> {
    private var relationshipKeyPathsObserver: RelationshipKeyPathsObserver<ResultType>?

    // MARK: - Lifecycle

    init(fetchRequest: FetchRequest<ResultType>,
         managedObjectContext context: NSManagedObjectContext,
         sectionNameKeyPath: String?,
         cacheName name: String?)
    {
        super.init(fetchRequest: fetchRequest,
                   managedObjectContext: context,
                   sectionNameKeyPath: sectionNameKeyPath,
                   cacheName: name)

        self.relationshipKeyPathsObserver = RelationshipKeyPathsObserver<ResultType>(
            keyPaths: fetchRequest.refreshingRelationships,
            fetchedResultsController: self
        )
    }
}
