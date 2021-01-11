//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeTopClipCollectionViewController() -> UIViewController?

    func makeClipPreviewPageViewController(clipId: Clip.Identity) -> UIViewController?
    func makeClipPreviewViewController(itemId: ClipItem.Identity, usesImageForPresentingAnimation: Bool) -> ClipPreviewViewController?

    func makeClipInformationViewController(clipId: Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           informationView: ClipInformationView,
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
