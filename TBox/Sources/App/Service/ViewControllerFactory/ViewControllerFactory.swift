//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeTopClipCollectionViewController(_ state: ClipCollectionViewRootState?) -> UIViewController?
    func makeTagCollectionViewController() -> UIViewController?
    func makeAlbumListViewController(_ state: AlbumListViewState?) -> UIViewController?
    func makeSearchViewController() -> UIViewController?
    func makeSettingsViewController(_ state: SettingsViewState?) -> UIViewController
    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController?
}
