//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

class FetchRequest<ResultType>: NSFetchRequest<NSFetchRequestResult> where ResultType: NSFetchRequestResult {
    var refreshingRelationships: Set<String> = []
}
