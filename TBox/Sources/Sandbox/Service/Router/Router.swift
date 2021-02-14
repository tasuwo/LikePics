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
    func showClipPreviewView(for clipId: Clip.Identity) -> Bool

    @discardableResult
    func showTagSelectionModal(selections: Set<Tag.Identity>, completion: ((Set<Tag.Identity>?) -> Void)?) -> Bool

    @discardableResult
    func showAlbumSelectionModal(completion: ((Album.Identity?) -> Void)?) -> Bool

    @discardableResult
    func showShareModal(from: ClipCollection.ShareSource, clips: Set<Clip.Identity>, completion: ((Bool) -> Void)?) -> Bool

    @discardableResult
    func showClipMergeModal(for clips: [Clip], completion: ((Bool) -> Void)?) -> Bool

    @discardableResult
    func showClipEditModal(for clip: Clip.Identity, completion: ((Bool) -> Void)?) -> Bool
}
