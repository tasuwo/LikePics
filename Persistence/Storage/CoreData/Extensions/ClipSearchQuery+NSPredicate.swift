//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipSearchQuery {
    var predicate: NSPredicate {
        var predicates: [NSPredicate] = []

        predicates += texts.map {
            NSPredicate(format: "SUBQUERY(clipItems, $item, $item.siteUrl.absoluteString CONTAINS[cd] %@).@count > 0", $0 as CVarArg)
        }
        predicates += albumIds.map {
            NSPredicate(format: "SUBQUERY(albumItem, $albumItem, $albumItem.album.id == %@).@count > 0", $0 as CVarArg)
        }
        predicates += tagIds.map {
            NSPredicate(format: "SUBQUERY(tags, $tag, $tag.id == %@).@count > 0", $0 as CVarArg)
        }

        switch isHidden {
        case .some(true):
            predicates.append(NSPredicate(format: "isHidden == true"))

        case .some(false):
            predicates.append(NSPredicate(format: "isHidden == false"))

        case .none:
            break
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
