//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol Router {
    @discardableResult
    func showUncategorizedClipCollectionView() -> Bool

    @discardableResult
    func showClipCollectionView(for tag: Tag) -> Bool

    @discardableResult
    func showClipCollectionView(for albumId: Album.Identity) -> Bool

    @discardableResult
    func showClipPreviewView(for clipId: Clip.Identity) -> Bool

    @discardableResult
    func showTagSelectionModal(selections: Set<Tag.Identity>, completion: @escaping (Set<Tag>?) -> Void) -> Bool

    @discardableResult
    func showAlbumSelectionModal(completion: ((Album.Identity?) -> Void)?) -> Bool

    @discardableResult
    func showShareModal(from: ClipCollection.ShareSource, clips: Set<Clip.Identity>, completion: ((Bool) -> Void)?) -> Bool

    @discardableResult
    func showClipMergeModal(for clips: [Clip], completion: @escaping (Bool) -> Void) -> Bool

    @discardableResult
    func showClipEditModal(for clip: Clip.Identity, completion: ((Bool) -> Void)?) -> Bool
}
