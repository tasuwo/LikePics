//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeClipCollectionViewController(from source: ClipCollection.Source) -> UIViewController & ViewLazyPresentable
    func makeClipCollectionViewController(_ state: ClipCollectionViewRootState) -> UIViewController & ViewLazyPresentable
    func makeTagCollectionViewController(_ state: TagCollectionViewState?) -> UIViewController?
    func makeAlbumListViewController(_ state: AlbumListViewState?) -> UIViewController?
    func makeSearchViewController(_ state: SearchViewRootState?) -> UIViewController?
    func makeSettingsViewController(_ state: SettingsViewState?) -> UIViewController
    func makeClipPreviewPageViewController(for clipId: Clip.Identity) -> UIViewController
    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController?
}
