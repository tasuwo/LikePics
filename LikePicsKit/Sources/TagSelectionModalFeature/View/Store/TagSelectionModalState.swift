//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain
import Foundation

public struct TagSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    let id: UUID
    let initialSelections: Set<Album.Identity>

    var searchQuery: String
    var searchStorage: SearchableStorage<Tag>
    var tags: EntityCollectionSnapshot<Tag>

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool
    var isSomeItemsHidden: Bool

    var quickAddButtonTitle: String?
    var isQuickAddButtonHidden: Bool

    var alert: Alert?

    var isDismissed: Bool
}

extension TagSelectionModalState {
    public init(id: UUID, selections: Set<Tag.Identity>, isSomeItemsHidden: Bool) {
        self.id = id
        initialSelections = selections

        searchQuery = ""
        searchStorage = .init()
        tags = .init()

        isCollectionViewHidden = true
        isEmptyMessageViewHidden = true
        isSearchBarEnabled = false
        isQuickAddButtonHidden = true
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil

        isDismissed = false
    }
}

extension TagSelectionModalState {
    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}
