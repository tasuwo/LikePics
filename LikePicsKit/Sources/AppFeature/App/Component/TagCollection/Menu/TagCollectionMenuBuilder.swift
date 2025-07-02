//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TagCollectionMenuBuildable {
    func build(for tag: Tag) -> [TagCollection.MenuItem]
}

struct TagCollectionMenuBuilder {
    // MARK: - Properties

    private let storage: UserSettingsStorageProtocol

    // MAKR: - Lifecycle

    init(storage: UserSettingsStorageProtocol) {
        self.storage = storage
    }
}

extension TagCollectionMenuBuilder: TagCollectionMenuBuildable {
    // MARK: - TagCollectionMenuBuildable

    func build(for tag: Tag) -> [TagCollection.MenuItem] {
        return [
            .copy,
            .rename,
            tag.isHidden
                ? .reveal
                : .hide(immediately: storage.readShowHiddenItems()),
            .delete,
        ]
    }
}
