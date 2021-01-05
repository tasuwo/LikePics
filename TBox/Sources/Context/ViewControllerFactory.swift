//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeTopClipCollectionViewController() -> UIViewController?

    func makeClipPreviewViewController(clipId: Clip.Identity) -> UIViewController?
    func makeClipItemPreviewViewController(itemId: ClipItem.Identity) -> ClipPreviewViewController?

    func makeClipInformationViewController(clipId: Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?

    func makeSearchEntryViewController() -> UIViewController
    func makeSearchResultViewController(context: ClipCollection.SearchContext) -> UIViewController?

    func makeAlbumListViewController() -> UIViewController?
    func makeAlbumViewController(albumId: Album.Identity) -> UIViewController?
    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController?

    func makeTagListViewController() -> UIViewController?
    func makeTagSelectionViewController(selectedTags: [Tag.Identity], context: Any?, delegate: TagSelectionDelegate) -> UIViewController?

    func makeMergeViewController(clips: [Clip], delegate: ClipMergeViewControllerDelegate) -> UIViewController

    func makeSettingsViewController() -> UIViewController
}
