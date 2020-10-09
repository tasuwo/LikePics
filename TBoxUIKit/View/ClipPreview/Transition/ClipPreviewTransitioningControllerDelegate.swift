//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol ClipPreviewTransitioningControllerDelegate: AnyObject {
    func didFailToPresent(_ controller: ClipPreviewTransitioningController)
    func didFailToDismiss(_ controller: ClipPreviewTransitioningController)
}
