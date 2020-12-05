//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipCollectionMenuBuildable {
    static func build(for clip: Clip, context: ClipCollection.Context) -> [ClipCollection.MenuItem]
}

enum ClipCollectionMenuBuilder: ClipCollectionMenuBuildable {
    // MARK: - ClipCollectionMenuBuildable

    static func build(for clip: Clip, context: ClipCollection.Context) -> [ClipCollection.MenuItem] {
        return [
            .addTag,
            context.isAlbum ? nil : .addToAlbum,
            clip.isHidden ? .unhide : .hide,
            context.isAlbum ? .removeFromAlbum : .delete
        ].compactMap { $0 }
    }
}
