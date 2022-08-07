//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

/**
 * - TODO: 個別のRouterに切り出し
 */
public protocol Router {
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
    func showClipPreviewView(filteredClipIds: Set<Clip.Identity>,
                             clips: [Clip],
                             query: ClipPreviewPageQuery,
                             indexPath: ClipCollection.IndexPath) -> Bool

    @discardableResult
    func showClipInformationView(clipId: Clip.Identity,
                                 itemId: ClipItem.Identity,
                                 transitioningController: ClipItemInformationTransitioningControllable) -> Bool

    @discardableResult
    func showFindView() -> Bool

    func routeToClipCollectionView(for tag: Tag)

    func routeToClipCollectionView(forAlbumId albumId: Album.Identity)
}
