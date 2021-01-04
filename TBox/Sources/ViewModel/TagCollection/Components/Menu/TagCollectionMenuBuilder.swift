//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TagCollectionMenuBuildable {
    static func build(for tag: Tag) -> [TagCollection.MenuItem]
}

enum TagCollectionMenuBuilder: TagCollectionMenuBuildable {
    // MARK: - TagCollectionMenuBuildable

    static func build(for tag: Tag) -> [TagCollection.MenuItem] {
        return [
            .copy,
            .rename,
            tag.isHidden ? .reveal : .hide,
            .delete
        ]
    }
}
