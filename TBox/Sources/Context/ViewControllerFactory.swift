//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeClipPreviewPageViewController(clipId: Clip.Identity) -> UIViewController?
    func makeClipPreviewViewController(itemId: ClipItem.Identity, usesImageForPresentingAnimation: Bool) -> ClipPreviewViewController?

    func makeClipInformationViewController(clipId: Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           informationView: ClipInformationView,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?

    func makeNewClipCollectionViewController() -> UIViewController?
    func makeNewTagListViewController() -> UIViewController?
    func makeNewAlbumListViewController() -> UIViewController?
    func makeSettingsViewController() -> UIViewController
}
