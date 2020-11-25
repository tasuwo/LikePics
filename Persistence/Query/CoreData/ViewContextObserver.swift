//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

protocol ViewContextObserver: AnyObject {
    func didReplaced(context: NSManagedObjectContext)
}
