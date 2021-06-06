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
    func showClipPreviewView(for clipId: Clip.Identity) -> Bool

    @discardableResult
    func showClipInformationView(clipId: Clip.Identity,
                                 itemId: ClipItem.Identity,
                                 clipInformationViewCache: ClipInformationViewCaching,
                                 transitioningController: ClipInformationTransitioningControllerProtocol) -> Bool

    @discardableResult
    func showTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) -> Bool

    @discardableResult
    func showAlbumSelectionModal(id: UUID) -> Bool

    @discardableResult
    func showClipMergeModal(id: UUID, clips: [Clip]) -> Bool

    @discardableResult
    func showClipEditModal(id: UUID, clipId: Clip.Identity) -> Bool

    func routeToClipCollectionView(for tag: Tag)

    func routeToClipCollectionView(forAlbumId albumId: Album.Identity)
}
