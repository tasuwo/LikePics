//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipCollectionMenuBuildable {
    func build(for clip: Clip, source: ClipCollectionState.Source) -> [ClipCollection.MenuElement]
}

struct ClipCollectionMenuBuilder {
    // MARK: - Properties

    private let storage: UserSettingsStorageProtocol

    // MARK: - Lifecycle

    init(storage: UserSettingsStorageProtocol) {
        self.storage = storage
    }
}

extension ClipCollectionMenuBuilder: ClipCollectionMenuBuildable {
    // MARK: - ClipCollectionMenuBuildable

    func build(for clip: Clip, source: ClipCollectionState.Source) -> [ClipCollection.MenuElement] {
        return [
            source.isAlbum
                ? .item(.addTag)
                : .subMenu(.init(kind: .add,
                                 isInline: false,
                                 children: [.item(.addTag), .item(.addToAlbum)])),
            clip.isHidden
                ? .item(.reveal)
                : .item(.hide(immediately: storage.readShowHiddenItems())),
            .item(.edit),
            .item(.share),
            .subMenu(.init(kind: .others,
                           isInline: true,
                           children: [
                               clip.items.count > 1 ? .item(.purge) : nil,
                               source.isAlbum ? .item(.removeFromAlbum) : .item(.delete)
                           ].compactMap { $0 }))
        ].compactMap { $0 }
    }
}
