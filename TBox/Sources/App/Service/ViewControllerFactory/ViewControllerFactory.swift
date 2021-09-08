//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeClipCollectionViewController(from source: ClipCollection.Source) -> RestorableViewController & ViewLazyPresentable
    func makeClipCollectionViewController(_ state: ClipCollectionViewRootState) -> RestorableViewController & ViewLazyPresentable
    func makeTagCollectionViewController(_ state: TagCollectionViewState?) -> RestorableViewController?
    func makeAlbumListViewController(_ state: AlbumListViewState?) -> RestorableViewController?
    func makeSearchViewController(_ state: SearchViewRootState?) -> RestorableViewController?
    func makeSettingsViewController(_ state: SettingsViewState?) -> RestorableViewController
    func makeClipPreviewPageViewController(for clipId: Clip.Identity,
                                           clips: EntityCollectionSnapshot<Clip>,
                                           source: ClipCollection.Source,
                                           at initialItem: ClipItem.Identity?) -> UIViewController
    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController?
}
