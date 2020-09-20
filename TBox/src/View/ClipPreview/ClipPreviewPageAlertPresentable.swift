//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipPreviewAlertPresentable: AnyObject {
    func presentAddAlert(addToAlbumAction: @escaping () -> Void, addTagsAction: @escaping () -> Void)
    func presentRemoveAlert(targetCount: Int, action: @escaping () -> Void)
    func presentRemoveFromAlbumAlert(targetCount: Int, deleteAction: @escaping () -> Void, removeFromAlbumAction: @escaping () -> Void)
    func presentHideAlert(targetCount: Int, action: @escaping () -> Void)
}

extension ClipPreviewAlertPresentable where Self: UIViewController {
    func presentRemoveFromAlbumAlert(targetCount: Int, deleteAction: @escaping () -> Void, removeFromAlbumAction: @escaping () -> Void) {
    }
}
