//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import WebKit

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
    func showClipItemListView(id: UUID,
                              clipId: Clip.Identity,
                              clipItems: [ClipItem],
                              transitioningController: ClipItemListTransitioningControllable) -> Bool

    @discardableResult
    func showAlbumSelectionModal(id: UUID) -> Bool

    @discardableResult
    func showClipMergeModal(id: UUID, clips: [Clip]) -> Bool

    @discardableResult
    func showFindView() -> Bool

    @discardableResult
    func showClipCreationModal(id: UUID, webView: WKWebView) -> Bool

    func routeToClipCollectionView(for tag: Tag)

    func routeToClipCollectionView(forAlbumId albumId: Album.Identity)
}
