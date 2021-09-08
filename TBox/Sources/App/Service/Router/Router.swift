//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit

protocol Router {
    @discardableResult
    func open(_ url: URL) -> Bool

    @discardableResult
    func showUncategorizedClipCollectionView() -> Bool

    @discardableResult
    func showClipCollectionView(for query: ClipSearchQuery) -> Bool

    @discardableResult
    func showClipCollectionView(for tag: Tag) -> Bool

    @discardableResult
    func showClipCollectionView(for albumId: Album.Identity) -> Bool

    @discardableResult
    func showClipPreviewView(filteredClipIds: [Clip.Identity],
                             clipsByIdentity: [Clip.Identity: Clip],
                             source: ClipCollection.Source,
                             indexPath: ClipCollection.IndexPath) -> Bool

    @discardableResult
    func showClipInformationView(clipId: Clip.Identity,
                                 itemId: ClipItem.Identity,
                                 clipInformationViewCache: ClipItemInformationViewCaching,
                                 transitioningController: ClipItemInformationTransitioningControllable) -> Bool

    @discardableResult
    func showClipItemListView(id: UUID,
                              clipId: Clip.Identity,
                              clipItems: [ClipItem],
                              transitioningController: ClipItemListTransitioningControllable) -> Bool

    @discardableResult
    func showTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) -> Bool

    @discardableResult
    func showAlbumSelectionModal(id: UUID) -> Bool

    @discardableResult
    func showClipMergeModal(id: UUID, clips: [Clip]) -> Bool

    func routeToClipCollectionView(for tag: Tag)

    func routeToClipCollectionView(forAlbumId albumId: Album.Identity)
}
