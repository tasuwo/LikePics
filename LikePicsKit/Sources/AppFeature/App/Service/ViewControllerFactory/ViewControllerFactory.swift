//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Environment
import LikePicsCore
import LikePicsUIKit
import UIKit

public protocol ViewControllerFactory {
    func makeClipCollectionViewController(from source: ClipCollection.Source) -> RestorableViewController & ViewLazyPresentable
    func makeClipCollectionViewController(_ state: ClipCollectionViewRootState) -> RestorableViewController & ViewLazyPresentable
    func makeTagCollectionViewController(_ state: TagCollectionViewState?) -> RestorableViewController?
    func makeAlbumListViewController(_ state: AlbumListViewState?) -> RestorableViewController?
    func makeSearchViewController(_ state: SearchViewRootState?) -> RestorableViewController?
    func makeSettingsViewController(_ state: SettingsViewState?) -> RestorableViewController
    func makeClipPreviewPageViewController(filteredClipIds: Set<Clip.Identity>,
                                           clips: [Clip],
                                           query: ClipPreviewPageQuery,
                                           indexPath: ClipCollection.IndexPath) -> UIViewController
    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController?
}
