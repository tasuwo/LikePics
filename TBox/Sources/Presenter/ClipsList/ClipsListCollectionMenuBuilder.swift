//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipsListCollectionMenuItem {
    case addTag
    case addToAlbum
    case hide
    case unhide
    case delete
}

enum ClipsListCollectionContext {
    case album
}

protocol ClipsListCollectionMenuBuildable {
    static func build(for clip: Clip, context: ClipsListCollectionContext?) -> [ClipsListCollectionMenuItem]
}

enum ClipsListCollectionMenuBuilder: ClipsListCollectionMenuBuildable {
    // MARK: - ClipsListCollectionMenuBuildable

    static func build(for clip: Clip, context: ClipsListCollectionContext?) -> [ClipsListCollectionMenuItem] {
        return [
            .addTag,
            context == .album ? nil : .addToAlbum,
            clip.isHidden ? .unhide : .hide,
            .delete
        ].compactMap { $0 }
    }
}
