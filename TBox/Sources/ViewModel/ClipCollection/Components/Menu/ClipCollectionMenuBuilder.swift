//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipCollectionMenuBuildable {
    static func build(for clip: Clip, context: ClipCollection.Context) -> [ClipCollection.MenuElement]
}

enum ClipCollectionMenuBuilder: ClipCollectionMenuBuildable {
    // MARK: - ClipCollectionMenuBuildable

    static func build(for clip: Clip, context: ClipCollection.Context) -> [ClipCollection.MenuElement] {
        return [
            context.isAlbum
                ? .item(.addTag)
                : .subMenu(.init(kind: .add,
                                 isInline: false,
                                 children: [.item(.addTag), .item(.addToAlbum)])),
            clip.isHidden ? .item(.unhide) : .item(.hide),
            .item(.share),
            .subMenu(.init(kind: .others,
                           isInline: true,
                           children: [
                               clip.items.count > 1 ? .item(.purge) : nil,
                               context.isAlbum ? .item(.removeFromAlbum) : .item(.delete)
                           ].compactMap { $0 }))
        ].compactMap { $0 }
    }
}
